#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	printf 'dagger-configure: ERROR: this command requires root privileges!\n'
	exit 1
fi

if [ ! -f /etc/dagger/profile.dag ]; then
	printf "dagger-configure: ERROR: '/etc/dagger/profile.dagger' doesn't exists!\n"
	exit 1
fi

if [ ! -d /var/cache/dagger/ ]; then
	printf "dagger-configure: ERROR: '/var/cache/dagger/ doesn't exists!'\n"
	exit 1
fi

# Parser

profile='/etc/dagger/profile.dag'

first_line="$(head -n 1 $profile)"
last_line="$(tail -n 1 $profile)"

profile_lines="$(wc -l < $profile)"

if [ ! "$first_line" = '{' ]; then
	printf "dagger-configure: ERROR: expected '%s' in line 1 but got '%s'\n" '{' "$first_line"
	exit 1
fi

if [ ! "$last_line" = '}' ]; then
	printf "dagger-configure: ERROR: expected '%s' in line $profile_lines but got '%s'\n" '}' "$last_line"
	exit 1
fi

# linux.hostname

if [ "$(grep -c 'linux.hostname' "$profile")" -ne 1 ]; then
	printf "dagger-configure: ERROR: field 'linux.hostname' not found or duplicated!\n"
	exit 1
fi

hostname="$(grep "linux.hostname" "$profile" | cut -d ' ' -f 2- | sed 's/^[[:blank:]]*//')"

if [ "$hostname" = 'linux.hostname' ] || [ "$(echo "$hostname" | awk '{printf NF}')" -ne 1 ] ; then
	printf "dagger-configure: ERROR: invalid 'linux.hostname' value\n"
	exit 1
fi

# build.compiler

if [ "$(grep -c 'build.compiler' "$profile")" -ne 1 ]; then
	printf "dagger-configure: ERROR: field 'build.compiler' not found or duplicated!\n"
	exit 1
fi

compiler="$(grep "build.compiler" "$profile" | cut -d ' ' -f 2- | sed 's/^[[:blank:]]*//')"

if [ "$compiler" = 'build.compiler' ] || [ "$(echo "$compiler" | awk '{printf NF}')" -ne 1 ] ; then
	printf "dagger-configure: ERROR: invalid 'build' value\n"
	exit 1
fi


# build.cflags

if [ "$(grep -c 'build.cflags' "$profile")" -ne 1 ]; then
	printf "dagger-configure: ERROR: field 'build.cflags' not found or duplicated!\n"
	exit 1
fi

cflags="$(grep "build.cflags" "$profile" | cut -d ' ' -f 2- | sed 's/^[[:blank:]]*//')"

if [ "$cflags" = 'build.cflags' ]; then
	printf "dagger-configure: ERROR: invalid 'build.cflags' value\n"
	exit 1
fi

# build.jobs

if [ "$(grep -c 'build.jobs' "$profile")" -ne 1 ]; then
	printf "dagger-configure: ERROR: field 'build.jobs' not found or duplicated!\n"
	exit 1
fi

jobs="$(grep "build.jobs" "$profile" | cut -d ' ' -f 2- | sed 's/^[[:blank:]]*//')"

if [ "$jobs" = 'build.jobs' ]; then
	printf "dagger-configure: ERROR: invalid 'build.jobs' value\n"
	exit 1
fi

# updating environment

exports='/var/cache/dagger/exports.sh'

: > "$exports"
printf "HOSTNAME='%s'\n" "$hostname" >> "$exports"
printf "COMPILER='%s'\n" "$compiler" >> "$exports"
printf "CFLAGS='%s'\n" "$cflags" >> "$exports"
printf "JOBS='%s'\n" "$jobs" >> "$exports"

echo "$hostname" > /etc/hostname

printf 'dagger-configure: your system has been successfully configured!\n'
