#!/bin/sh

# zorn.converge
#
# This script reads '/etc/zorn/profile.zorn', parse it, validate the 
# configuration, and then save to '/var/cache/zorn/exports.sh'.
#
# Copyright (C) 2026 Miguel Barbosa (hltloop)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

set -u

# Configuration

readonly PROFILE='/etc/zorn/profile.zorn'
readonly EXPORTS='/var/cache/zorn/exports.sh'

# State flags

hostname_found=0
prefix_found=0
c_compiler_found=0
c_flags_found=0
cxx_compiler_found=0
cxx_flags_found=0
jobs_found=0

inside_braces=0

# Counters

line_number=0

# Profile values

hostname=''
prefix=''
c_compiler=''
c_flags=''
cxx_compiler=''
cxx_flags=''
jobs=''

check_profile() # {{{
{
	if [ ! -e "$PROFILE" ]; then
		printf "zorn.converge: ERROR: '%s' not found\n" "$PROFILE"
		exit 1
	fi
} # }}}

check_root() # {{{
{
	if [ "$(id -u)" -ne 0 ]; then
		printf "zorn.converge: ERROR: this command must be run with root privileges\n"
		exit 1
	fi
} # }}}

# $1 = field string
# $2 = field variable
# $3 = field found

parse_field() # {{{
{
	case $command in
		"$1")
			if [ "$inside_braces" -eq 0 ]; then
				printf "zorn.converge: ERROR: field '%s' outside braces\n" "$1"
				exit 1
			fi

			eval "field_found=\$$3"

			if [ "$field_found" -eq 1 ]; then
				printf "zorn.converge: ERROR: %s: duplicated '%s'\n" "$line_number" "$1"
				exit 1
			fi

			eval "$2=\$argument"
			eval "$3=1"
			;;
	esac
} # }}}

# $1 = field string
# $2 = field found

check_field() # {{{
{
	eval field_found="\$$2"
	if [ "$field_found" -eq 0 ]; then
		printf "zorn.converge: ERROR: missing '%s' field\n" "$1"
		exit 1
	fi
} # }}}

parse_configuration() # {{{
{
	first_line="$(head -1 "$PROFILE")"
	second_line="$(sed -n '2p' "$PROFILE")"
	last_line="$(tail -1 "$PROFILE")"

	if [ "$first_line" != 'main' ]; then
		printf "zorn.converge: ERROR: 1: expected 'main' but got '%s'\n" "$first_line"
		exit 1
	fi

	if [ "$second_line" != '{' ]; then
		printf "zorn.converge: ERROR: 2: expected '{' but got '%s'\n" "$second_line"
		exit 1
	fi

	if [ "$last_line" != '}' ]; then
		printf "zorn.converge: ERROR: %s: expected '}' but got '%s'\n" "$(wc -l < "$PROFILE")" "$last_line"
		exit 1
	fi
	
	while IFS= read -r line; do
		line_number=$((line_number+1))

		case $line in
			'{')
				inside_braces=1
				;;
		esac

		case $line in
			'}')
				inside_braces=0
				;;
		esac

		# Finally parsing the actual configuration

		command=$(printf '%s\n' "$line" | cut -d ' ' -f1 | tr -d '\t')
		argument=$(printf '%s\n' "$line" | cut -d ' ' -f2- | tr -d '\t')

		case $command in
			'main'|'{'|'}')
				;;
			'linux.hostname'|'build.prefix'|'build.c.compiler'|'build.c.flags'|'build.cxx.compiler'|'build.cxx.flags'|'build.jobs')
				;;
			*)
				printf "zorn.converge: ERROR: %s: unrecognized field '%s'\n" "$line_number" "$command"
				exit 1
		esac

		parse_field "linux.hostname" hostname hostname_found

		parse_field "build.prefix" prefix prefix_found

		parse_field "build.c.compiler" c_compiler c_compiler_found
		parse_field "build.c.flags" c_flags c_flags_found

		parse_field "build.cxx.compiler" cxx_compiler cxx_compiler_found
		parse_field "build.cxx.flags" cxx_flags cxx_flags_found

		parse_field "build.jobs" jobs jobs_found
	done < "$PROFILE"
} # }}}

# $1 string

escape_quote() # {{{
{
	printf '%s' "$1" | sed "s|'|'\\\\''|g"
} # }}}

check_and_save_configuration() # {{{
{
	check_field 'linux.hostname' hostname_found
	check_field 'build.prefix' prefix_found
	check_field 'build.c.compiler' c_compiler_found
	check_field 'build.c.flags' c_flags_found
	check_field 'build.cxx.compiler' cxx_compiler_found
	check_field 'build.cxx.flags' cxx_flags_found
	check_field 'build.jobs' jobs_found

	echo "$hostname" > /etc/hostname

	if ! mkdir -p "$(dirname "$EXPORTS")"; then
		printf "zorn.converge: failed to create '%s'\n" "$(dirname "$EXPORTS")"
		exit 1
	fi

	cat <<EOF > "$EXPORTS.tmp"
PREFIX='$(escape_quote "$prefix")'
CC='$(escape_quote "$c_compiler")'
CFLAGS='$(escape_quote "$c_flags")'
CXX='$(escape_quote "$cxx_compiler")'
CXXFLAGS='$(escape_quote "$cxx_flags")'
JOBS='$(escape_quote "$jobs")'
EOF

	sync
	mv "$EXPORTS.tmp" "$EXPORTS"
} # }}}

main() # {{{
{
	check_profile
	check_root
	parse_configuration
	check_and_save_configuration
	
	printf "zorn.converge: successfully converged your system\n"
} # }}}

main
