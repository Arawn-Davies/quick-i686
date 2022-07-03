#!/bin/bash
set -e

# Set the versions of the assembler,
# compiler and debugger to download & build

BINUTILS_VERSION="2.37"
GCC_VERSION="11.2.0"
GDB_VERSION="11.1"
OUTPUT=true
# Number of jobs = Number of CPU Cores + 1
export MAKEFLAGS="-j$(nproc)"


# Archive type, xz has smaller size but extracts longer, gz opposite 
# Choose 'xz' if you're low on disk space, or have bad internet, 
# or 'gz' if you've got time to kill

AT="gz"

cd $HOME

function pause {
    read -s -n 1 -p "Press any key to continue . . ."
    echo ""
}

function SetVars {

    echo -e "\033[92mExport variables \033[0m"
	export PREFIX="$HOME/.i686-elf/"
	export TARGET=i686-elf
	export PATH="$PREFIX/bin:$PATH"
}

function persistVars {
	# echo "#compiler target arch variables for i686-elf-* (OSDev)"
	echo 'export PREFIX="$HOME/.i686-elf/"' >> $HOME/.bashrc
	echo "export TARGET=i686-elf" >> $HOME/.bashrc
	echo 'export PATH="$PREFIX/bin:$PATH"' >> $HOME/.bashrc
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

function DownloadSources () {
    
	echo -e "\033[92mDownload sources\033[0m"
    if [ "$AT" == "gz" ]
    then
        echo "Using GZIP compression"
    fi
    if [ "$AT" == "xz" ]
    then
        echo "Using LZMA compression"
    fi
    if [ $OUTPUT == false ]
    then
        wget -cq https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.$AT
	    wget -cq https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.$AT
    	wget -cq https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.$AT

    else
        wget -c https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.$AT
	    wget -c https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.$AT
	    wget -c https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.$AT

    fi
	
	if [ "$AT" == "gz" ]	
	then
		for filename in *.tar.gz
		do	
		    echo -e "\033[92mExtracting tar.gz archive...\033[0m"
            if [ $OUTPUT == false ]
            then
                tar -xzf $filename > /dev/null
            else
    			tar -xvzf $filename
            fi
		done
	elif [ "$AT" == "xz" ]
	then
		for filename in *.tar.xz
		do	
		    echo -e "\033[92mExtracting tar.xz archive...\033[0m"
			if [ $OUTPUT == false ]
            then
                tar -xf $filename
            else
                tar -xvf $filename
            fi
		done
	fi

	echo -e "\033[92mDownload GCC prerequisites\033[0m"
	cd gcc-*/
    if [ $OUTPUT == false ]
    then
        contrib/download_pre* > /dev/null
    else
        contrib/download_pre*
    fi
	cd ..
}

# Onto the main build!

function MakeBinutils {
	
    echo -e "\033[92mConfigure, build and install binutils\033[0m"
	cd build-binutils
	    if [ $OUTPUT == false ]
    then
        ../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror > binutils-configure.txt > /dev/null
        make -j$(nproc) > binutils-make.txt > /dev/null 
	    make install > binutils-install.txt > /dev/null
	else
        ../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror > binutils-configure.txt
        make -j$(nproc) > binutils-make.txt
	    make install > binutils-install.txt
    fi
	cd ..
}

function MakeGCC {

    echo -e "\033[92mConfigure, build and install GCC cross compiler\033[0m"
	which -- $TARGET-as || echo $TARGET-as is not in the PATH
	cd build-gcc
	../gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++,go --without-headers > gcc-configure.txt
	make all-gcc -j$(nproc) >  all-gcc.txt 
	make all-target-libgcc -j$(nproc) > all-target-libgcc.txt
	make install-gcc > install-gcc.txt
	make install-target-libgcc > install-target-libgcc.txt
	cd ..
}

function MakeGDB {
	
    echo -e "\033[92mConfigure, build and install GDB\033[0m"
	cd build-gdb
	../gdb-$GDB_VERSION/configure --target=$TARGET --disable-nls --disable-werror --prefix=$PREFIX > gdb-configure.txt
	make -j$(nproc) > gdb-make.txt
	make install > gdb-install.txt
	cd ..
}

function cleanUp {

        echo -e "\033[92mCleaning up source files...\033[0m"
	rm -rf i686-elf-src
}

function main() {

	arg=$1
    if [ "$*" == "silent" ]
    then
        OUTPUT=false
    fi
    if [ "$arg" == "--clean" ] || [ "$arg" == "-c" ]
	then
		cleanUp
	elif [ "$arg" == "--download" ] || [ "$arg" == "-dl" ]
	then
		SetVars
		mkdirs
		DownloadSources
	elif [ "$arg" == "makebin" ]
	then
		echo -e "\033[92mMaking i686 Binutils\033[0m"
		SetVars
		mkdirs
		MakeGDB
		cleanUp
	elif [ "$arg" == "makegcc" ]
	then
		echo -e "\033[92mMaking i686 Binutils + GCC\033[0m"
		SetVars
		mkdirs
		MakeBinutils
		MakeGCC
		cleanUp
	elif [ "$arg" == "makegdb" ]
	then
		echo -e "\033[92mMaking i686 Binutils + GDB\033[0m"
		SetVars
		mkdirs
		MakeBinutils
		MakeGDB
		cleanUp
	elif [ "$arg" == "nopersist" ]
	then
                SetVars
                mkdirs
                DownloadSources
                MakeBinutils
                MakeGCC
                MakeGDB
                cleanUp
    else
	    if [ $OUTPUT == false ]
        then
            echo -e "\033[92mRunning quietly...\033[0m"
        else
            echo -e "\033[92mRunning normally...\033[0m"
		fi
        SetVars
		mkdirs
		persistVars
		DownloadSources

		MakeBinutils
		MakeGCC
		MakeGDB

		cleanUp
	fi
}

main $@
