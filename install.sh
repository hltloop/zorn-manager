#!/bin/sh

readonly ETC='/etc/zorn'
readonly CACHE='/var/cache/zorn'
readonly LIBEXEC='/usr/libexec/zorn'

readonly RECIPES_DIR='/usr/share/zorn/database'
readonly INSTALLED_DIR='/var/lib/zorn/installed'

update=${UPDATE:-0}

# Checking for root

if [ "$(id -u)" -ne 0 ]; then
	printf 'install.sh: ERROR: this script requires root privileges\n'
	exit 1
fi

# Preventing unexistent directories

if ! mkdir -p $CACHE; then
	printf "install.sh: ERROR: failed to create '%s'\n" "$CACHE"
	exit 1
fi

if ! mkdir -p $ETC; then
	printf "install.sh: ERROR: failed to create '%s'\n" "$ETC"
	exit 1
fi

if ! mkdir -p $LIBEXEC; then
	printf "install.sh: ERROR: failed to create '%s'\n" "$LIB"
	exit 1
fi

if ! mkdir -p $RECIPES_DIR; then
	printf "install.sh: ERROR: failed to create '%s'\n" "$LIB"
	exit 1
fi

if ! mkdir -p $INSTALLED_DIR; then
	printf "install.sh: ERROR: failed to create '%s'\n" "$LIB"
	exit 1
fi

# Installating the commands

if ! install -m 755 zorn.converge.sh /usr/bin/zorn.converge; then
	printf "install.sh: ERROR: failed to install 'zorn.converge'\n"
	exit 1
fi

if ! install -m 755 zorn.packages.sh /usr/bin/zorn.packages; then
	printf "install.sh: ERROR: failed to install 'zorn.converge'\n"
	exit 1
fi

if ! install -m 755 zorn.forge.sh $LIBEXEC/forge.sh; then
	printf "install.sh: ERROR: failed to install '%s'\n" "$LIBEXEC/forge.sh"
	exit 1
fi

# Base profile.zorn if desired

if [ "$update" -eq 0 ]; then
	cat > /etc/zorn/profile.zorn <<EOF
main
{
	linux.hostname your-hostname

	build.prefix /usr
	
	build.c.compiler clang
	build.c.flags -O2 -march=native
	
	build.cxx.compiler clang++	
	build.cxx.flags -O2 -march=native

	build.jobs 12	
}
EOF
cat > /etc/zorn/packages.zorn <<EOF
packages
{
	package editor/vim
		build.attributes ncurses
		install.overwrite yes

	package lib/libxa
		install.overwrite no
}
EOF
	printf "The installation is done! Don't forget to edit '/etc/zorn/profile.zorn' and '/etc/zorn/packages.zorn':)\n"
else
	printf "Sucessfully updated zorn!\n"
fi
