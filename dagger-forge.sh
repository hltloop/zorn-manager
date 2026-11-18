#!/bin/sh

if [ ! -f /var/cache/dagger/exports.sh ]; then
	printf "dagger-forge: ERROR: '/var/cache/dagger/exports.sh' wasn't found, maybe try running 'dagger-rebuild'\n"
	exit 1
fi

. /var/cache/dagger/exports.sh

export COMPILER CFLAGS JOBS

if [ "$#" -eq 0 ]; then
	printf 'dagger-forge: ERROR: this command requires an argument\n'
	exit 1
fi

for arg in "$@"; do
	if [ ! -d "/var/lib/dagger/database/$arg" ]; then
		printf "dagger-forge: ERROR: package '/var/lib/dagger/database/$arg' not found\n"
		exit 1
	fi

	# Temporary directory
	tmp_dir="$(mktemp -d)"
	cd $tmp_dir
	
	export DESTDIR="$(mktemp -d $tmp_dir/destdir.XXXXXX)"

	# Parameters
	
	NOCHECK="${NOCHECK:-0}"

	# Fetching
	if ! sh "/var/lib/dagger/database/$arg/build.sh" fetch_sources; then
		printf "dagger-forge: ERROR: fetch_sources for '$arg' failed!\n"
		rm -rf $tmp_dir
		exit 1
	fi

	# Prepare
	if ! sh "/var/lib/dagger/database/$arg/build.sh" prepare_build; then
		printf "dagger-forge: ERROR: prepare_build for '$arg' failed!\n"
		rm -rf $tmp_dir
		exit 1
	fi

  # From now on we don't remove $tmp_dir for debugging)
	#
	# Build 
	
	if ! sh "/var/lib/dagger/database/$arg/build.sh" build_package; then
		printf "dagger-forge: ERROR: build for '$arg' failed!\n"
		exit 1
	fi

	# Install (everything occurs on a destdir)
	
	if ! sh "/var/lib/dagger/database/$arg/build.sh" install_package; then
		printf "dagger-forge: ERROR: install for '$arg' failed!\n"
		exit 1
	fi

	# Now we are recording a manifest
	
	if ! mkdir -p "/var/lib/dagger/installed/$arg" || 
		! (
				cd $DESTDIR || exit 1
				find . \( -type f -o -type l \) | sed 's|.||'
			) > "/var/lib/dagger/installed/$arg/manifest"; 
	then
		printf "dagger-forge: ERROR: manifest generation for '$arg' failed!\n"
		exit 1
	fi
	
	# And finally we install it to the system
	
	while IFS= read -r line; do
		if [ $NOCHECK -eq 0 ]; then
			printf "dagger-forge: checking file '$line'\n"
			if [ -e $line ]; then
				printf '%s already exists, skipping...\n' $line
				continue
			fi
		fi

		if ! mkdir -p "$(dirname "$line")"; then
			printf "dagger-forge: ERROR: instalattion for '$arg' failed!\n"
			exit 1
		fi

		printf "dagger-forge: installed file '$line'\n"
	done < "/var/lib/dagger/installed/$arg/manifest"

	if ! rsync -a --no-perms $DESTDIR/ /; then
		printf "dagger-forge: ERROR: instalattion for '$arg' failed!\n"
		exit 1
	fi

	printf "dagger-forge: instalattion for '$arg' completed successfully\n"

done
