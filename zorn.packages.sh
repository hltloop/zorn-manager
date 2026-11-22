#!/bin/sh

# zorn.packages
#
# This script function is read '/var/cache/zorn/exports.sh', and them
# install/remove the necessary packages.
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

readonly PACKAGES='/etc/zorn/packages.zorn'
readonly EXPORTS='/var/cache/zorn/exports.sh'

readonly INSTALL_COMMAND='/usr/libexec/zorn/forge.sh'

# Counters

line_number=0

# Package values 

current_package=
package_attributes=
package_overwrite=

check_packages() # {{{
{
	if [ ! -e $PACKAGES ]; then
		printf "zorn.packages: ERROR: '%s' not found\n" "$PACKAGES"
		exit 1
	fi
} # }}}

check_root() # {{{
{
	if [ "$(id -u)" -ne 0 ]; then
		printf 'zorn.packages: ERROR: this command must be ran with root privileges\n'
		exit 1
	fi
} # }}}

install_package() # {{{
{	
	[ -z "$current_package" ] && return 0
	
	if [ -z "$package_overwrite" ]; then
		printf "zorn.packages: ERROR: %s: 'install.overwrite' field is obligatory\n" "$line_number"
		exit 1
	fi
	
	case $package_overwrite in
	'yes')
		if ! $INSTALL_COMMAND "$current_package" 1 "$package_attributes"; then
			exit 1
		fi
		;;
	'no')
		if ! $INSTALL_COMMAND "$current_package" 0 "$package_attributes"; then
			exit 1
		fi
		;;
	*)
		printf "zorn.packages: ERROR: %s: 'install.overwrite' only arguments must be 'yes' or 'no'\n" "$line_number"
		exit 1
	esac
} # }}}

parse_packages() # {{{
{
	while IFS= read -r line; do
		line_number=$((line_number+1))

		first_line="$(head -1 $PACKAGES)"
		second_line="$(sed -n '2p' $PACKAGES)"
		last_line="$(tail -1 $PACKAGES)"

		if [ "$first_line" != 'packages' ]; then
			printf "zorn.converge: ERROR: line 1 must be 'packages'\n"
			exit 1
		fi

		if [ "$second_line" != '{' ]; then
			printf "zorn.converge: ERROR: line 2 must be '{'\n"
			exit 1
		fi

		if [ "$last_line" != '}' ]; then
			printf "zorn.converge: ERROR: line $(wc -l $PACKAGES) must be '}'\n"
			exit 1
		fi

		function=$(echo $line | cut -d ' ' -f 1)
		argument=$(echo $line | cut -d ' ' -f 2-)
	
		case $function in
			'packages'|'{'|'}'|'')
				continue
				;;
			'package')
				if [ -z "$argument" ]; then
					printf 'zorn.packages: ERROR: %s: unspecified package\n' "$line_number"
					exit 1
				fi

				install_package

				current_package=$argument
				package_attributes=
				package_overwrite=
				;;
			'build.attributes')
				package_attributes=$argument
				;;
			'install.overwrite')
				package_overwrite=$argument
				;;
		esac
	done < $PACKAGES

	install_package
} # }}}

main() # {{{
{
	check_packages
	check_root
	parse_packages
	
	printf "zorn.packages: sucessfully installed the packages to your system\n"
} # }}}

main
