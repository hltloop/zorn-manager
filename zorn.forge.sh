#!/bin/sh

# zorn.forge
#
# This script works along with 'zorn.packages' to install the packages declared
# in 'system.packages'. Its function is read '/var/cache/zorn/exports.sh', run
# the scripts in the '/usr/share/zorn/database/<package>/' (e.g,
# '/usr/share/zorn/database/editor/vim/') and them commit the files from a DESTDIR 
# to the real filesystem.
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

readonly EXPORTS='/var/cache/zorn/exports.sh'
readonly DATABASE='/usr/share/zorn/database'
readonly MANIFESTS='/var/lib/zorn/installed'
readonly LIB='/usr/lib/zorn/lib.sh'

# Source lib

. "$LIB"

read_exports() # {{{
{
	if [ ! -f "$EXPORTS" ]; then
		printf "zorn.forge: ERROR: '%s' wasn't found, maybe try running 'zorn.converge'\n" "$EXPORTS"
		exit 1
	fi

	. "$EXPORTS"

	export PREFIX CC CFLAGS CXX CXXFLAGS JOBS
} # }}}

# $1 package
# $2 overwrite
# $3 attributes

install_package() # {{{
{
	# Already installed
	
	if [ -e "$MANIFESTS/$1" ]; then
		printf "zorn.forge: '%s' is already installed\n" "$1"
		exit 0
	fi

	if [ ! -d "$DATABASE/$1" ]; then
		printf "zorn.forge: ERROR: package '%s' not found\n" "$DATABASE/$1"
		exit 1
	fi

	printf "zorn.forge: installating '%s'\n" "$1"

	# Temporary directory

	tmp_dir="$(mktemp -d)"
	cd "$tmp_dir" || exit 1

	if ! DESTDIR="$(mktemp -d "$tmp_dir"/destdir.XXXXXX)"; then
		printf "zorn.forge: ERROR: failed to create DESTDIR for '%s'\n" "$1"
	fi
	export DESTDIR

	# Parameters

	OVERWRITE="${2:-0}"

	# Fetching
	if ! sh "$DATABASE/$1/build.sh" fetch_sources; then
		printf "zorn.forge: ERROR: fetch_sources for '%s' failed!\n" "$1"
		rm -rf "$tmp_dir"
		exit 1
	fi

	# Prepare
	if ! sh "$DATABASE/$1/build.sh" prepare_build; then
		printf "zorn.forge: ERROR: prepare_build for '%s' failed!\n" "$1"
		rm -rf "$tmp_dir"
		exit 1
	fi

	# From now on we don't remove $tmp_dir for debugging
	#
	# Build
	
	if ! ZORN_BUILD_ATTRIBUTES="$3" sh "$DATABASE/$1/build.sh" build_package ; then
		printf "zorn.forge: ERROR: build for '%s' failed!\n temporary directory wasn't removed for debugging: '%s'\n" "$1" "$tmp_dir"
		exit 1
	fi

	# Install on the destdir

	if ! sh "$DATABASE/$1/build.sh" install_package; then
		printf "zorn.forge: ERROR: install for '%s' failed!\n temporary directory wasn't removed for debugging: '%s'\n" "$1" "$tmp_dir"
		exit 1
	fi

	# Installing on the filesystem

	if [ "$OVERWRITE" -eq 0 ]; then
		rsync -rl --ignore-existing "$DESTDIR"/ /
	else
		rsync -rl "$DESTDIR"/ /
	fi

	# Manifest

	if ! mkdir -p "$MANIFESTS/$1" || ! : > "$MANIFESTS/$1/manifest"; then
		printf "zorn.forge: ERROR: failed to create '%s' manifest\n" "$1"
		exit 1
	fi

	find "$DESTDIR" -type f > "$tmp_dir/files" || exit 1

	while IFS= read -r destdir_file; do
		filesystem_file="${destdir_file#"$DESTDIR"}"

		if ! printf '%s\n' "$filesystem_file" >> "$MANIFESTS/$1/manifest"; then
			printf "zorn.forge: FATAL: failed to append '%s' to '%s' manifest, system may be unstable!\n" "$filesystem_file" "$1"
			exit 1
		fi
	done < "$tmp_dir/files"

	printf "zorn.forge: successfully installed '%s'\n" "$1"
} # }}}

main() # {{{
{
	check_root
	read_exports
	install_package "$1" "$2" "$3"
} # }}}

main "$@"
