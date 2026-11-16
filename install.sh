#!/bin/sh

update=${UPDATE:-0}

if [ "$(id -u)" -ne 0 ]; then
	printf 'install.sh: ERROR: this script requires root privileges\n'
	exit 1
fi

if ! mkdir -p /var/cache/dagger; then
	printf "install.sh: ERROR: failed to create '/var/cache/dagger'\n"
	exit 1
fi

if ! mkdir -p /etc/dagger; then
	printf "install.sh: ERROR: failed to create '/etc/dagger'\n"
	exit 1
fi

if ! install -m 755 dagger-configure.sh /usr/bin/dagger-configure; then
	printf "install.sh: ERROR: failed to install 'dagger-configure'\n"
	exit 1
fi

if ! install -m 755 dagger-forge.sh /usr/bin/dagger-forge; then
	printf "install.sh: ERROR: failed to install 'dagger-forge'\n"
	exit 1
fi

if [ "$update" -eq 0 ]; then
	cat > /etc/dagger/profile.dag <<EOF
{
	linux.hostname your-hostname
	
	build.compiler clang
	build.cflags -O2 -march=native
	build.jobs -j6
}
EOF
	printf "The installation is done! Don't forget to edit '/etc/dagger/profile.dag' :)\n"
else
	printf "Sucessfully updated dagger!\n"
fi
