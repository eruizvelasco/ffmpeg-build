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

# download ffmpeg source code
git clone https://github.com/FFmpeg/FFmpeg.git

# download some base develpement tool dependencies
pacman -S base-devel git mercurial cvs wget p7zip
pacman -S perl ruby python2 mingw-w64-i686-toolchain mingw-w64-x86_64-toolchain
pacman -S gnutls
pacman -S p11-kit

# install the following packages
pacman -S libsndfile
pacman -S python
pacman -S nasm
pacman -S unzip
pacman -S ed
pacman -S cvs
pacman -S mercurial
pacman -S mingw-w64-x86_64-gnutls
pacman -S libhogweed
pacman -S mingw-w64-x86_64-libass
pacman -S cmake
pacman -S mingw-w64-x86_64-fontconfig
#pacman -S mingw-w64-x86_64-libmodplug
pacman -S mingw-w64-x86_64-lame
pacman -S mingw-w64-x86_64-opencore-amr
pacman -S mingw-w64-x86_64-openh264
pacman -S mingw-w64-x86_64-openjpeg
pacman -S mingw-w64-x86_64-opus
pacman -S mingw-w64-x86_64-rtmpdump
pacman -S mingw-w64-x86_64-snappy
pacman -S mingw-w64-x86_64-libtheora
pacman -S mingw-w64-x86_64-twolame

# p11 encryption library - dowload and build without trust paths
git clone https://github.com/p11-glue/p11-kit
cd p11-kit
mkdir build
cd build
./autogen.sh --prefix=/mingw64 --without-trust-paths --enable-static CFLAGS="-static" LDFLAGS="-static"
make all install

# download & build - libilbc 
rm -r libilbc
git clone https://github.com/TimothyGu/libilbc.git

# modify the following lines in CMakeList.txt
# option(BUILD_SHARED_LIBS "Build a shared library instead of a static one" ON)
# add_library(ilbc STATIC ${ilbc_source_files})

cd libilbc
cmake . -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF
make all install
cd ..

# download & build - mfx_dispatch 
rm -r mfx_dispatch
git clone https://github.com/lu-zero/mfx_dispatch.git
cd mfx_dispatch
./configure --prefix=/mingw64
make -j$(nproc) install
cd ..

# libsooxr
rm -r soxr-code
git clone https://git.code.sf.net/p/soxr/code soxr-code
cd soxr-code
./go
cd Release
make install
cd ..

# vo-amrbenc
rm -r vo-amrbenc
git clone https://github.com/mstorsjo/vo-amrwbenc.git
cd vo-amrbenc
pacman -S pkg-config libtool automake
libtoolize --force
aclocal
automake --force-missing --add-missing
autoconf
cmake -DCMAKE_INSTALL_PREFIX:PATH=/mingw64
./configure --prefix=/mingw64
make all install
cd ..

#XAVS
rm -r xavs-code
svn checkout https://svn.code.sf.net/p/xavs/code/trunk xavs-code
cd xavs-code
./configure --prefix=/mingw64
make all install
cd ..

#zimg
rm -r zimg
git clone https://github.com/sekrit-twc/zimg.git
cd zimg
./autogen.sh
./configure --prefix=/mingw64
make all install
cd ..

#harfbuzz
pacman -S mingw-w64-x86_64-graphite2
git clone https://github.com/behdad/harfbuzz.git
mkdir build
cd build
../configure --prefix=/mingw64 --with-gobject CFLAGS=-DGRAPHITE2_STATIC CPPFLAGS=-DGRAPHITE2_STATIC --enable-static && make
make install

# game-music-emu
git clone https://bitbucket.org/mpyne/game-music-emu.git
cd game-music-emu
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF
make 
make install
cd ../../

# libmodplug
git clone https://github.com/Konstanty/libmodplug.git
cd libmodplug
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=/mingw64 -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-DMODPLUG_BUILD -DMODPLUG_STATIC"
make 
make install
cd ../../

#librtmp
git clone git://git.ffmpeg.org/rtmpdump
cd rtmpdump/librtmp
make SYS=mingw CRYPTO=
cp *.a /mingw64/lib
cd ../../

#xvid code
cd build/generic &&
sed -i 's/^LN_S=@LN_S@/& -f -v/' platform.inc.in &&
./configure --prefix=/mingw64 &&
make
make install &&
chmod -v 755 /mingw64/lib/libxvidcore.so.4.3 &&
install -v -m755 -d /mingw64/share/doc/xvidcore-1.3.3/examples &&
install -v -m644 ../../doc/* /mingw64/share/doc/xvidcore-1.3.3 &&
install -v -m644 ../../examples/* \
    /mingw64/share/doc/xvidcore-1.3.3/examples
cp =build/xvidcore.a /mingw64/lib/libxvidcore.a
cd ../../../../

# build ffmpeg with CUDA
cd ffmpeg
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
--extra-cflags=-I/$CUDA_PATH/include \
--extra-cflags=-I/./frei0r-plugins-1.6.1/include \
--extra-cflags=-I/./mfx_dispatch \
--extra-cflags=-DMODPLUG_STATIC \
--extra-ldflags=-L"/$CUDA_PATH/lib/x64" \
--extra-ldflags=-fopenmp \
--extra-ldflags=-static \
--extra-ldflags=-static-libgcc \
--extra-ldflags=-static-libstdc++ \
--extra-ldflags=-Bstatic \
--extra-ldflags=-lstdc++ \
--extra-ldflags=-lpthread \
--extra-ldflags=-Bdynamic \
--pkg-config-flags="--static" \
--disable-shared \
--enable-static \
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
make