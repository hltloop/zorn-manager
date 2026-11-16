#!/bin/sh

if [ ! -f /var/cache/dagger/exports.sh ]; then
	printf "dagger-force: ERROR: '/var/cache/dagger/exports.sh' wasn't found, maybe try running 'dagger-rebuild'\n"
fi

. /var/cache/dagger/exports.sh

echo "$COMPILER"
echo "$CFLAGS"
echo "$JOBS"
