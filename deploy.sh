#!/bin/bash
set -e

# Set the versions of the assembler,
# compiler and debugger to download & build

BINUTILS_VERSION="2.37"
GCC_VERSION="11.2.0"
GDB_VERSION="11.1"

# Number of jobs = Number of CPU Cores + 1
cpus=$(getconf _NPROCESSORS_ONLN)
cpus=$((cpus+1))
export MAKEFLAGS="-j "$cpus


# Archive type, xz has smaller size but extracts longer, gz opposite 
# Choose 'xz' if you're low on disk space, or have bad internet, 
# or 'gz' if you've got time to kill

AT="xz"

cd $HOME

function SetVars {

        echo -e "\033[92mExport variables \033[0m"
	export PREFIX="$HOME/.i686-elf/"
	export TARGET=i686-elf
	export PATH="$PREFIX/bin:$PATH"
}

function mkdirs {
	
        echo -e "\033[92mCreating directories...\033[0m"
	mkdir -p i686-elf-src
	cd i686-elf-src 
	# Make directories
	mkdir -p build-binutils
	mkdir -p build-gcc
	mkdir -p build-gdb
	mkdir -p $HOME/.i686-elf
}

function DownloadSources {

	echo -e "\033[92mDownload sources\033[0m"
	wget -c https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.$AT

	if [ "$AT" == "gz" ]	
	then
		for filename in *.tar.gz
		do	
		        echo -e "\033[92m Extracting tar.gz archive...\033[0m"
			tar -xvzf $filename
		done
	elif [ "$AT" == "xz" ]
	then
		for filename in *.tar.xz
		do	
		        echo -e "\033[92m Extracting tar.xz archive...\033[0m"
			tar -xvf $filename
		done
	fi

	echo -e "\033[92mDownload GCC prerequisites\033[0m"
	cd gcc-*/
	contrib/download_pre*
	cd ..
}

# Onto the main build!

function MakeBinutils {
	
        echo -e "\033[92mConfigure, build and install binutils\033[0m"
	cd build-binutils
	../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror > binutils-configure.txt
	make > binutils-make.txt
	make install > binutils-install.txt
	cd ..
}

function MakeGCC {

        echo -e "\033[92mConfigure, build and install GCC cross compiler\033[0m"
	# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
	which -- $TARGET-as || echo $TARGET-as is not in the PATH
	cd build-gcc
	../gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++,go --without-headers > gcc-configure.txt
	make all-gcc >  all-gcc.txt
	make all-target-libgcc > all-target-libgcc.txt
	make install-gcc > install-gcc.txt
	make install-target-libgcc > install-target-libgcc.txt
	cd ..
}

function MakeGDB {
	
        echo -e "\033[92mConfigure, build and install GDB\033[0m"
	cd build-gdb
	../gdb-$GDB_VERSION/configure --target=$TARGET --disable-nls --disable-werror --prefix=$PREFIX > gdb-configure.txt
	make > gdb-make.txt
	make install > gdb-install.txt
	cd ..
}

function cleanUp {

        echo -e "\033[92mCleaning up source files...\033[0m"
	rm -rf i686-elf-src
}

function main() {

	arg=$1
	if [ "$arg" == "--clean" ] || [ "$arg" == "-c" ]
	then
		cleanUp
	elif [ "$arg" == "--download" ] || [ "$arg" == "-dl" ]
	then
		SetVars
		mkdirs
		DownloadSources
	elif [ "$arg" == "makegdb" ]
	then
		echo -e "\033[92mMaking GDB\033[0m"
		SetVars
		mkdirs
		MakeGDB
		cleanUp
	else
	        echo -e "\033[92mRunning normally\033[0m"
		SetVars
		mkdirs

		DownloadSources

		MakeBinutils
		MakeGCC
		MakeGDB

		cleanUp
	fi
}

main $@
