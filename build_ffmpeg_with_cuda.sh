# build_ffmpeg_with_cuda.sh
#
# by Enrique Ruiz-Velasco, enrique.velasco@gmail.com, all rights reserved and copyright 2017. 
# use this file under L-GPL licence
#
# This script will download and build static ffmpeg windows executable with all dependencies 
# similar to the zeranoe builds and enabled for NVIDIA Cuda acceleration.
#
# Dependencies: MSYS2 MingW 64 (http://www.msys2.org/), CUDA SDK v8.0 pre-installed
#
# This script was tested with MSYS2 MingW 64 and assumes is already installed. 
# Just run this script in the folder where you want ffmpeg & all dependencies to be downloaded
# Open the MSYS2 MinW 64 console and run this script at the prompt ./build_ffmpeg.sh 
# Note: make sure you don't have other MingW or other versions of make, cmake in your path
#

# save the current directory
BUILD_DIR="$PWD"
LIB_DIR="$PWD/lib"
INCLUDE_DIR="$PWD/include"

cd "$BUILD_DIR"

echo Installing all development tools and pre-compiled dependencies
# download some base develpement tool dependencies
pacman -S --noconfirm base-devel git mercurial cvs wget p7zip
pacman -S --noconfirm perl ruby python2 mingw-w64-i686-toolchain mingw-w64-x86_64-toolchain
pacman -S --noconfirm gnutls
pacman -S --noconfirm p11-kit

# install the following packages
pacman -S --noconfirm libsndfile
pacman -S --noconfirm python
pacman -S --noconfirm nasm
pacman -S --noconfirm unzip
pacman -S --noconfirm ed
pacman -S --noconfirm cvs
pacman -S --noconfirm mercurial
pacman -S --noconfirm mingw-w64-x86_64-gnutls
pacman -S --noconfirm libhogweed
pacman -S --noconfirm mingw-w64-x86_64-libass
pacman -S --noconfirm cmake
pacman -S --noconfirm mingw-w64-x86_64-fontconfig
#pacman -S --noconfirm mingw-w64-x86_64-libmodplug
pacman -S --noconfirm mingw-w64-x86_64-lame
#pacman -S --noconfirm mingw-w64-x86_64-libgme
pacman -S --noconfirm mingw-w64-x86_64-opencore-amr
pacman -S --noconfirm mingw-w64-x86_64-openh264
pacman -S --noconfirm mingw-w64-x86_64-openjpeg
pacman -S --noconfirm mingw-w64-x86_64-opus
pacman -S --noconfirm mingw-w64-x86_64-rtmpdump
pacman -S --noconfirm mingw-w64-x86_64-snappy
pacman -S --noconfirm mingw-w64-x86_64-libtheora
pacman -S --noconfirm mingw-w64-x86_64-twolame
pacman -S --noconfirm mingw-w64-x86_64-graphite2
pacman -S --noconfirm pkg-config libtool automake

# p11 encryption library - dowload and build without trust paths
echo Building p11-kit...
rm -r -f p11-kit
git clone https://github.com/p11-glue/p11-kit
cd p11-kit
#mkdir build
#cd build
#aclocal -I build/m4
./autogen.sh --prefix=/mingw64 --without-trust-paths --disable-shared --enable-static CFLAGS="-static" LDFLAGS="-static"
#./configure --prefix=/mingw64 --without-trust-paths #--enable-static CFLAGS="-static" LDFLAGS="-static"
make
make install
cd "$BUILD_DIR"

# download_and_unpack GNUTLS file 
echo Building GNUTLS...
rm -r -f gnutls-3.5.14
wget https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnutls/v3.5/gnutls-3.5.14.tar.xz
tar -xf gnutls-3.5.14.tar.xz
cd gnutls-3.5.14
# --disable-cxx don't need the c++ version, in an effort to cut down on size... XXXX test size difference...
# --enable-local-libopts to allow building with local autogen installed,
# --disable-guile is so that if it finds guile installed (cygwin did/does) it won't try and link/build to it and fail...
# libtasn1 is some dependency, appears provided is an option [see also build_libnettle]
# pks #11 hopefully we don't need kit
if [[ ! -f lib/gnutls.pc.in.bak ]]; then # Somehow FFmpeg's 'configure' needs '-lcrypt32'. Otherwise you'll get "undefined reference to `_imp__Cert...'" and "ERROR: gnutls not found using pkg-config".
  sed -i.bak "/privat/s/.*/& -lcrypt32/" lib/gnutls.pc.in
fi
./configure --prefix=/mingw64 --disable-shared --enable-static --disable-doc --disable-tools --disable-cxx --disable-tests --disable-gtk-doc-html --disable-libdane --disable-nls --enable-local-libopts --disable-guile --with-included-libtasn1 --with-included-unistring --without-p11-kit
make
make install
cd "$BUILD_DIR"

# download & build - libilbc
echo Building libilbc... 
rm -r -f libilbc
git clone https://github.com/TimothyGu/libilbc.git

# modify the following lines in CMakeList.txt
# option(BUILD_SHARED_LIBS "Build a shared library instead of a static one" ON)
# add_library(ilbc STATIC ${ilbc_source_files})

cd libilbc
cmake . -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF
make all install
cd "$BUILD_DIR"

# download & build - mfx_dispatch 
echo Building mfx_dispatch...
rm -r -f mfx_dispatch
git clone https://github.com/lu-zero/mfx_dispatch.git
cd mfx_dispatch
./configure --prefix=/mingw64
make -j$(nproc) install
cd "$BUILD_DIR"

# libsooxr
echo Building soxr-code...
rm -r -f soxr-code
git clone https://git.code.sf.net/p/soxr/code soxr-code
cd soxr-code
./go
cd Release
make install
cd "$BUILD_DIR"

# vo-amrbenc
echo Building vo-amrbenc...
rm -r -f vo-amrbenc
git clone https://github.com/mstorsjo/vo-amrwbenc.git
cd vo-amrbenc
libtoolize --force
aclocal
automake --force-missing --add-missing
autoconf
cmake -DCMAKE_INSTALL_PREFIX:PATH=/mingw64
./configure --prefix=/mingw64
make all install
cd "$BUILD_DIR"

#XAVS
echo Building xavs-code...
rm -r -f xavs-code
svn checkout https://svn.code.sf.net/p/xavs/code/trunk xavs-code
cd xavs-code
./configure --prefix=/mingw64
make all install
cd "$BUILD_DIR"

#zimg
echo Building zimg...
rm -r -f zimg
git clone https://github.com/sekrit-twc/zimg.git
cd zimg
./autogen.sh
./configure --prefix=/mingw64
make all install
cd "$BUILD_DIR"

#harfbuzz
echo Building harfbuzz...
rm -r -f harfbuzz
git clone https://github.com/behdad/harfbuzz.git
mkdir build
cd build
../configure --prefix=/mingw64 --with-gobject CFLAGS=-DGRAPHITE2_STATIC CPPFLAGS=-DGRAPHITE2_STATIC --enable-static && make
make install
cd "$BUILD_DIR"

# game-music-emu
echo Building game-music-emu...
rm -r -f game-music-emu
git clone https://bitbucket.org/mpyne/game-music-emu.git
cd game-music-emu
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF -DENABLE_UBSAN=OFF
make 
make install
cd "$BUILD_DIR"

# libmodplug
echo Building libmodplug...
rm -r -f libmodplug
git clone https://github.com/Konstanty/libmodplug.git
cd libmodplug
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-DMODPLUG_BUILD -DMODPLUG_STATIC"
make 
make install
cd "$BUILD_DIR"

#librtmp
echo Building rtmpdump...
rm -r -f rtmpdump
git clone git://git.ffmpeg.org/rtmpdump
cd rtmpdump/librtmp
make SYS=mingw CRYPTO=
cp *.a /mingw64/lib
cd "$BUILD_DIR"

#xvid code
echo Building xvidcore...
rm -r -f xvidcore
wget http://downloads.xvid.org/downloads/xvidcore-1.3.4.tar.gz
tar -xvzf xvidcore-1.3.4.tar.gz
cd xvidcore/build/generic &&
sed -i 's/^LN_S=@LN_S@/& -f -v/' platform.inc.in &&
./configure --prefix=/mingw64 &&
make
make install &&
chmod -v 755 /mingw64/lib/libxvidcore.so.4.3 &&
install -v -m755 -d /mingw64/share/doc/xvidcore-1.3.3/examples &&
install -v -m644 ../../doc/* /mingw64/share/doc/xvidcore-1.3.3 &&
install -v -m644 ../../examples/* \
    /mingw64/share/doc/xvidcore-1.3.3/examples
cp build/xvidcore.a /mingw64/lib/libxvidcore.a
cd "$BUILD_DIR"

echo Building frei0r-plugins...
rm -r -f frei0r-plugins
wget https://files.dyne.org/frei0r/frei0r-plugins-1.6.1.tar.gz
tar -xvzf frei0r-plugins-1.6.1.tar.gz
cd frei0r-plugins-1.6.1
./autogen.sh
./configure --prefix=/mingw64 --enable-static --disable-shared
make
make install DESTDIR=/mingw64/lib
cd "$BUILD_DIR"

# copy cuda SDK lib and include files 
echo Copy CUDA include and lib files to $PWD/cuda
mkdir cuda
cp -R -f "$CUDA_PATH/include" "$BUILD_DIR/cuda/include"
cp -R -f "$CUDA_PATH/lib" "$BUILD_DIR/cuda/lib"

# download ffmpeg source code
echo Building ffmpeg...
rm -r -f FFmpeg
git clone https://github.com/FFmpeg/FFmpeg.git

# configure & make ffmpeg
cd ffmpeg
echo Configuring FFmpeg...
./configure \
--arch=x86_64 \
--target-os=mingw64 \
--pkg-config=pkg-config \
--enable-cuda \
--enable-cuvid \
--enable-nvenc \
--enable-nonfree \
--enable-libnpp \
--extra-cflags=-fopenmp \
--extra-cflags=-static \
--enable-static \
--disable-shared \
--extra-cflags=-I"$BUILD_DIR/cuda/include" \
--extra-cflags=-I"$BUILD_DIR/frei0r-plugins-1.6.1/include" \
--extra-cflags=-I"$BUILD_DIR/mfx_dispatch" \
--extra-cflags=-DMODPLUG_STATIC \
--extra-ldflags=-L"$BUILD_DIR/cuda/lib/x64" \
--extra-ldflags=-fopenmp \
--extra-ldflags=-static \
--extra-ldflags=-static-libgcc \
--extra-ldflags=-static-libstdc++ \
--extra-ldflags=-Bstatic \
--extra-ldflags=-lstdc++ \
--extra-ldflags=-lpthread \
--extra-ldflags=-Bdynamic \
--extra-ldflags=-lcrypt32 \
--extra-ldflags=-lcrypto \
--pkg-config-flags="--static" \
--enable-gpl \
--enable-version3 \
--enable-d3d11va \
--enable-dxva2 \
--enable-libmfx \
--enable-avisynth \
--enable-bzlib \
--enable-fontconfig \
--enable-frei0r \
--enable-iconv \
--enable-libass \
--enable-libbs2b \
--enable-libcaca \
--enable-libfreetype \
--enable-libgme \
--enable-libgsm \
--enable-libilbc \
--enable-libmodplug \
--enable-libmp3lame \
--enable-libopencore-amrnb \
--enable-libopencore-amrwb \
--enable-libopenh264 \
--enable-libopenjpeg \
--enable-libopus \
--enable-librtmp \
--enable-libsnappy \
--enable-libsoxr \
--enable-libspeex \
--enable-libtheora \
--enable-libtwolame \
--enable-libvidstab \
--enable-libvo-amrwbenc \
--enable-libvorbis \
--enable-libvpx \
--enable-libwavpack \
--enable-libwebp \
--enable-libx264 \
--enable-libx265 \
--enable-libxavs \
--enable-libxvid \
--enable-libzimg \
--enable-lzma \
--enable-zlib
echo Making FFmpeg...
make clean
make
echo Build completed successfully!...