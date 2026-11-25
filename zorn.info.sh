#!/bin/sh

# zorn.info
#
# This script displays information for a requested package. It reads '/usr/share/zorn/database/<package>'
# to check if it exists, and them displays the avaliable information of the package (such as 
# name, version, description, build.attributes, 
#
# This script reads a manifest from a package in '/var/lib/zorn/installed/<package>/manifest'
# (e.g, '/var/lib/zorn/installed/editor/vim/manifest'), deletes each file written on it, and
# finally delete the folder itself, purging the package from the system.
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

readonly DATABASE='/usr/share/zorn/database'
readonly MANIFESTS='/var/lib/zorn/installed'
readonly BUILD_INFO='/var/cache/zorn/installed' # BUILD_LOGS
readonly LIB='/usr/lib/zorn/lib.sh'

# Source lib

. "$LIB"

# Package values

status='not installed'

# Colors

BOLD=$(printf '\033[1m')

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')

CYAN=$(printf '\033[36m')

RESET=$(printf '\033[0m')

main() # {{{
{
	if [ "$#" -eq 0 ]; then
		printf "zorn.info: ERROR: this command must receive an argument\n"
		exit 1
	fi

	for package in "$@"; do
		if [ ! -e "$DATABASE/$package" ]; then
			printf "zorn.info: ERROR: package '%s' not found\n" "$DATABASE/$package"
			exit 1
		fi

		if [ -e "$MANIFESTS/$package" ]; then
			status='installed'
		fi

		# Getting the package variables (VERSION, DESCRIPTION
		
		. "$DATABASE/$package/info.sh"

		# Package info
		
		printf '\n'
		printf '%s%s %s%s ' "$BOLD" "$package" "$VERSION" "$RESET"
		if [ "$status" = 'installed' ]; then
			printf '%s[installed]%s' "$GREEN" "$RESET"
		else
			printf '%s[not installed]%s' "$RED" "$RESET"
		fi

		printf '\n'
		
		printf '%s\n' "$DESCRIPTION"
		printf 'build.attributes:\n'
		printf '	%savailable%s: %s\n' "$CYAN" "$RESET" "$BUILD_ATTRIBUTES"

		if [ "$status" = 'installed' ]; then
			printf '	%senabled%s: %s\n' "$GREEN" "$RESET" "$(cat $BUILD_INFO/$package/build_attributes)"
			printf 'build date: %s\n' "$(cat $BUILD_INFO/$package/date)"
		else
			printf '	%senabled%s: none\n' "$GREEN" "$RESET"
		fi

	done

} # }}}

main "$@"
