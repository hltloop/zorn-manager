#!/bin/sh

# zorn.converge
#
# This script is the main core of zorn-manager, its function is read
# '/etc/zorn/profile.zorn', parse it and validate the configuration, save
# to '/var/cache/zorn/exports.sh' and then install the packages
# declared in field 'system.packages' using '/usr/libexec/zorn/forge.sh'.
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

# Configuration

readonly PROFILE='/etc/zorn/profile.zorn'
readonly EXPORTS='/var/cache/zorn/exports.sh'
readonly INSTALL_COMMAND='/usr/libexec/zorn/forge.sh'

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
	if [ ! -e $PROFILE ]; then
		printf "zorn.converge: ERROR: '%s' not found\n" "$PROFILE"
		exit 1
	fi
} # }}}

check_root() # {{{
{
	if [ "$(id -u)" -ne 0 ]; then
		printf "zorn.converge: ERROR: this command must be ran with root privileges\n"
		exit 1
	fi
} # }}}

# $1 = field string
# $2 = field variable
# $3 = field found

parse_field() # {{{
{
	case $command in
		$1)
			if [ $inside_braces -eq 0 ]; then
				printf "zorn.converge: ERROR: field '$1' outside braces\n"
				exit 1
			fi

			eval "field_found=\$$3"

			if [ $field_found -eq 1 ]; then
				printf "zorn.converge: ERROR: duplicated '$1' at line %s\n" $line_number
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
	if [ $field_found -eq 0 ]; then
		printf "zorn.converge: ERROR: missing '$1' field\n"
		exit 1
	fi
} # }}}

parse_configuration() # {{{
{
	while IFS= read -r line; do
		line_number=$((line_number+1))

		first_line="$(head -1 $PROFILE)"
		second_line="$(sed -n '2p' $PROFILE)"
		last_line="$(tail -1 $PROFILE)"

		if [ "$first_line" != 'main' ]; then
			printf "zorn.converge: ERROR: line 1 must be 'main'\n"
			exit 1
		fi

		if [ "$second_line" != '{' ]; then
			printf "zorn.converge: ERROR: line 2 must be '{'\n"
			exit 1
		fi

		case $line in
			'{')
				inside_braces=1
				;;
		esac

		if [ "$last_line" != '}' ]; then
			printf "zorn.converge: ERROR: line $(wc -l $PROFILE) must be '}'\n"
			exit 1
		fi

		case $line in
			'}')
				inside_braces=0
				;;
		esac

		# Finally parsing the actual configuration

		command=$(printf '%s\n' "$line" | cut -d ' ' -f1 | tr -d '\t')
		argument=$(printf '%s\n' "$line" | cut -d ' ' -f2- | tr -d '\t')

		parse_field "linux.hostname" hostname hostname_found

		parse_field "build.prefix" prefix prefix_found

		parse_field "build.c.compiler" c_compiler c_compiler_found
		parse_field "build.c.flags" c_flags c_flags_found

		parse_field "build.cxx.compiler" cxx_compiler cxx_compiler_found
		parse_field "build.cxx.flags" cxx_flags cxx_flags_found

		parse_field "build.jobs" jobs jobs_found
	done < $PROFILE
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

	cat <<EOF > $EXPORTS
PREFIX='$prefix'
CC='$c_compiler'
CFLAGS='$c_flags'
CXX='$cxx_compiler'
CXXFLAGS='$cxx_flags'
JOBS='$jobs'
EOF
} # }}}

# The packages must be installed after updating the system

install_packages() # {{{
{
	line_number=0

	while IFS= read -r line; do
		line_number=$((line_number+1))

		command=$(printf '%s\n' "$line" | cut -d ' ' -f1 | tr -d '\t')
		argument=$(printf '%s\n' "$line" | cut -d ' ' -f2- | tr -d '\t')

		case $command in
			'system.packages')
				next_line=$((line_number+1))
				content=$(sed -n "${next_line}p" $PROFILE | tr -d '\t')

				if [ "$content" != '[' ]; then
					printf "zorn.converge: ERROR: 'system.packages' next line must be '['\n"
					exit 1
				fi

				while [ "$content" != ']' ]; do
					next_line="$((next_line+1))"
					total_lines="$(wc -l < $PROFILE)"

					content=$(sed -n "${next_line}p" $PROFILE | tr -d '\t')

					if [ "$next_line" -ge "$total_lines" ]; then
						printf "zorn.converge: ERROR: '[' not closed\n"
						exit 1
					fi

					if [ "$content" != ']' ]; then
						package="$(echo $content | cut -d ' ' -f1)"
						argument="$(echo $content | cut -d ' ' -f2)"
						extra="$(echo $content | cut -d ' ' -f3-)"

						if [ -n "$extra" ]; then
							printf 'zorn.converge: ERROR: invalid package argument\n'
						fi

						if [ "$argument" = "$package" ]; then
							$INSTALL_COMMAND "$package" 0
						else
							case $argument in
								OVERWRITE)
									$INSTALL_COMMAND "$package" 1
									;;
								*)
									printf 'zorn.converge: ERROR: invalid package argument\n'
									exit 1
									;;
							esac
						fi
					fi
				;;
				done
		esac
	done < $PROFILE
} # }}}

main() # {{{
{
	check_profile
	check_root
	parse_configuration
	check_and_save_configuration
	install_packages

	printf "zorn.converge: sucessfully converged your system\n"
} # }}}

main
