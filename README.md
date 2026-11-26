# zorn-manager

## Description

zorn-manager is a minimal declarative package manager written in POSIX shell.

## Dependencies

zorn-manager only depends on busybox/binutils and a POSIX compatible shell.

## Installation and updating

As root:
```sh
./install.sh
```

Or if you desire only to update the files without creating new configuration files:
```sh
UPDATE=1 ./install.sh
```

##  How It Works

### Overview

zorn-manager basically reads POSIX shell scripts to download, build and install packages (packages avaliable at [zorn-packages](https://github.com/hltloop/zorn-packages)).

### zorn.converge

```zorn.converge``` reads the ```/etc/zorn/profile.zorn```, parses it, update hostname and exports the config to ```/var/cache/zorn/exports.sh``` so ```zorn.forge``` can pass it to each package ```build.sh```.

So after every change on the profile.zorn you must run ```zorn.converge```.

a ```/etc/zorn/profile.zorn``` looks like this:

```zorn
main
{
	linux.hostname rikka

	build.prefix /usr

	build.c.compiler clang
	build.c.flags -O2 -march=native

	build.cxx.compiler clang++
	build.cxx.flags -O2 -march=native

	build.jobs 12
}
```

### zorn.packages and /etc/zorn/packages.zorn
 
```zorn.packages``` reads ```/etc/zorn/packages.zorn```, parses it and pass each package name and its attributes to ```zorn.forge```.

a ```/etc/zorn/packages.zorn``` looks like this:

```zorn
packages
{
	package editor/vim
		build.attributes wayland
		install.overwrite yes

	package system/consolation
		install.overwrite no
	
	package build/texinfo
		build.attributes year2038
		install.overwrite no
	
	package terminal/bc
		install.overwrite yes
	
	package lib/libevent
		build.attributes year2038
		install.overwrite no

	package terminal/tmux
		build.attributes static optimizations
		install.overwrite no
}
```

Each package has two options, which are ```build.attributes``` and ```install.overwrite```.

### zorn.forge

This is the script that really install the package. It receives three parameters:
```sh
$1 = package name
$2 = overwrite attribute
$3 = build attributes
```

It looks for ```/usr/share/zorn/database/<package-name>/build.sh``` and executes ```fetch_sources```,  ```prepare_build```,  ```build_package``` and ```install_package```.

Note: For more details of each step and how create your own recipes, check [zorn-packages](https://github.com/hltloop/zorn-packages).

```zorn.forge``` first install the package on a DESTDIR for two reasons:
1. System security: If the installation fails halfway through the user doesn't have a incomplete package in the filesystem.
2. Manifest recording: With this approach it's easier and more practical recording packages manifests.

After everything succeeds it copies everything to the filesystem using ```rsync```. If the package has ```install.overwrite yes``` rsync will NOT preserve existing files.

So if you have:
```zorn
	package editor/vim
		build.attributes wayland
		install.overwrite yes
```
in your ```/etc/zorn/packages.zorn```, zorn.forge will run ```/usr/share/zorn/database/editor/vim/build.sh``` functions, building the package with wayland support and overwriting any file that already exists.

### zorn.purge

This script function is remove package(s) from the filesystem by reading its manifest, deleting each file on it, and them deleting the manifest itself, e.g.:

```sh
$ zorn.purge editor/vim 
# the previous command is going to read /var/lib/zorn/installed/editor/vim/manifest
# it also supports multiple packages
$ zorn.purge editor/vim editor/nano
```

### zorn.info

As the name suggests, this script display packages information, e.g.:
```sh
$ zorn.info system/consolation

system/consolation 0.0.10 [installed]
Consolation is a daemon that provide copy-paste and scrolling support to the linux console.
build.attributes:
	available: silent-rules
	enabled: 
build date: 2026-11-25 01:31:14
$
```

Or if the package isn't installed:
```sh
$ zorn.info build/bison

build/bison 3.8.2 [not installed]
GNU Automake is a software development tool to automate parts of the compilation process. It eases common compilation problems. For example, it points to needed dependencies.
build.attributes:
	available: silent-rules largefile year2038 rpath yacc asserts relocatable nls
	enabled: none
$
```

## LICENSE

This project and all its files are licensed under the GPL-3.0 license. For details check [LICENSE](LICENSE).
