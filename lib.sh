#!/bin/sh

# lib.sh
#
# Several utils for zorn-manager scripts and zorn-packages build.sh
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

# zorn-manager

check_root() # {{{
{
	if [ "$(id -u)" -ne 0 ]; then
		printf 'zorn.packages: ERROR: this command must be ran with root privileges\n'
		exit 1
	fi
} # }}}

# zorn-packages

reset_logs()
{
	: > "$BUILD_LOGS/build_attributes"
	: > "$BUILD_LOGS/date"
}

fetch_sources()
{
	for link in $SOURCES; do
		if curl -fL -o "$TARGET.tarball" "$link"; then
			printf 'fetch_sources: successfully download %s\n' "$TARGET"
			exit 0
		else
			printf 'fetch_sources: download failed, trying next mirror\n'
		fi
	done

	printf 'fetch_sources: ERROR: all mirrors failed\n'
	exit 1
}

prepare_build()
{
	mkdir -p "$TARGET"
	tar -xvf "$TARGET.tarball" --strip-components=1 -C "$TARGET"
}

install_package()
{
	cd "$TARGET" || exit 1
	if ! DESTDIR="$DESTDIR" make install; then
		printf "install_package: ERROR: failed to install '%s'\n" "$PACKAGE_NAME"
		reset_logs
		exit 1
	fi
}
