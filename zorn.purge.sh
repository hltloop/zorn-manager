#!/bin/sh

# zorn.purge
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

readonly MANIFESTS='/var/lib/zorn/installed'
readonly LIB='/usr/lib/zorn/lib.sh'

# Source lib.sh

. "$LIB"

# $1 package

purge_package() # {{{
{
	# Must have an argument
	
	if [ "$#" -eq 0 ]; then
		printf 'zorn.purge: ERROR: this command must receive an argument\n'
		exit 1
	fi

	# Not installed
	
	for package in "$@"; do
		case $package in
			*'.'*)
				printf "zorn.purge: ERROR: use a valid package name\n"
				exit 1
				;;
		esac
		
		manifest="$MANIFESTS/$package/manifest"
	
		if [ ! -e "$manifest" ]; then
			printf "zorn.purge: ERROR: package '%s' isn't installed\n" "$package"
			exit 1
		fi

		while IFS= read -r file; do
			printf "zorn.purge: removing '%s'...\n" "$file"
			if ! rm "$file"; then
				printf "zorn.purge: FATAL: failed to remove '%s'! System may be unstable\n" "$file"
				exit 1
			fi
		done < "$manifest"

		if rm -rf "$MANIFESTS/$package"; then
			printf "zorn.purge: successfully purged '%s' from your system\n" "$package"
		else
			printf "zorn.purge: ERROR: failed to remove manifest for '%s'\n" "$package"
			exit 1
		fi
	done
} # }}}

main() # {{{
{
	check_root
	purge_package "$@"
} # }}}

main "$@"
