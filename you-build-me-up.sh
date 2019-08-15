#!/bin/bash
set -e

# Set the versions of the assembler,
# compiler and debugger to download & build

BINUTILS_VERSION="2.32"
GCC_VERSION="9.1.0"
GDB_VERSION="8.3"

# Archive type, xz has smaller size but extracts longer, gz opposite 
# Choose 'xz' if you're low on disk space, or have bad internet, 
# or 'gz' if you've got time to kill

AT="gz"

cd $HOME

function SetVars {
	# Export variables
	export PREFIX="$HOME/.i686-elf/"
	export TARGET=i686-elf
	export PATH="$PREFIX/bin:$PATH"
}

function mkdirs {
	mkdir -p i686-elf-src
	cd i686-elf-src 
	# Make directories
	mkdir -p build-binutils
	mkdir -p build-gcc
	mkdir -p build-gdb
	mkdir -p $HOME/.i686-elf
}

function DownloadSources {
	# Download sources
	wget -c https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.$AT

	if [ "$AT" == "gz" ]	
	then
		for filename in *.tar.gz
		do
			tar -xvzf $filename
		done
	elif [ "$AT" == "xz" ]
	then
	
		for filename in *tar.xz
		do
			tar -xvf $filename
		done
	fi

	# Download GCC prerequisites
	cd gcc-*/
	contrib/download_pre*
	cd ..
}

# Onto the main build!

function MakeBinutils {
	# Configure, build and install binutils
	cd build-binutils
	../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX/bin" --with-sysroot --disable-nls --disable-werror
	make
	make install
	cd ..
}

function MakeGCC {
	# Configure, build and install GCC cross compiler
	# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
	which -- $TARGET-as || echo $TARGET-as is not in the PATH
	cd build-gcc
	../gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$PREFIX/bin" --disable-nls --enable-languages=c,c++,go --without-headers
	make all-gcc
	make all-target-libgcc
	make install-gcc
	make install-target-libgcc
	cd ..
}

function MakeGDB {
	# Configure, build and install GDB
	cd build-gdb
	../gdb-$GDB_VERSION/configure --target=$TARGET --disable-nls --disable-werror --prefix=$PREFIX/bin
	make
	make install
	cd ..
}

function cleanUp {
	rm -rf i686-elf-src
}

function main() {

#	for arg in "$@"
#	do
	arg=$1
	    if [ "$arg" == "--clean" ] || [ "$arg" == "-c" ]
	    then
	        echo "Cleaning up files..."
	    	cleanUp
	    elif [ "$arg" == "--download" ] || [ "$arg" == "-dl" ]
		then
			SetVars
			mkdirs
			echo "Downloading sources..."
			DownloadSources
		else
			echo "Running normally"
			SetVars
			mkdirs
			
			DownloadSources

			MakeBinutils
			MakeGCC
			MakeGDB
		
			cleanUp
		fi
#	done
}

main $@
