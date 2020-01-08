#!/bin/bash
set -e

# Set the versions of the assembler,
# compiler and debugger to download & build

BINUTILS_VERSION="2.33.1"
GCC_VERSION="9.2.0"
GDB_VERSION="8.3"

# Archive type, xz has smaller size but extracts longer, gz opposite 
# Choose 'xz' if you're low on disk space, or have bad internet, 
# or 'gz' if you've got time to kill

AT="gz"

cd $HOME

function SetVars {

        echo -e "\e[92mExport variables"
	export PREFIX="$HOME/.i686-elf/"
	export TARGET=i686-elf
	export PATH="$PREFIX/bin:$PATH"
}

function mkdirs {
	
        echo -e "\e[92mCreating directories..."
	mkdir -p i686-elf-src
	cd i686-elf-src 
	# Make directories
	mkdir -p build-binutils
	mkdir -p build-gcc
	mkdir -p build-gdb
	mkdir -p $HOME/.i686-elf
}

function DownloadSources {

	echo -e "\e[92mDownload sources"
	wget -c https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.$AT
	wget -c https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.$AT

	if [ "$AT" == "gz" ]	
	then
		for filename in *.tar.gz
		do	
		        echo -e "\e[92m Extracting tar.gz archive..."
			tar -xvzf $filename
		done
	elif [ "$AT" == "xz" ]
	then
		for filename in *.tar.xz
		do	
		        echo -e "\e[92m Extracting tar.xz archive..."
			tar -xvf $filename
		done
	fi

	echo -e "\e[92mDownload GCC prerequisites"
	cd gcc-*/
	contrib/download_pre*
	cd ..
}

# Onto the main build!

function MakeBinutils {
	
        echo -e "\e[92mConfigure, build and install binutils"
	cd build-binutils
	../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror > binutils-configure.txt
	make > binutils-make.txt
	make install > binutils-install.txt
	cd ..
}

function MakeGCC {

        echo -e "\e[92mConfigure, build and install GCC cross compiler"
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
	
        echo -e "\e[92mConfigure, build and install GDB"
	cd build-gdb
	../gdb-$GDB_VERSION/configure --target=$TARGET --disable-nls --disable-werror --prefix=$PREFIX > gdb-configure.txt
	make > gdb-make.txt
	make install > gdb-install.txt
	cd ..
}

function cleanUp {

        echo -e "\e[92mCleaning up source files..."
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
	else		
	        echo -e "\e[92mRunning normally"
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
