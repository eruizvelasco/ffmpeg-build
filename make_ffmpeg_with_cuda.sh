BUILD_DIR="$PWD"
cd "$BUILD_DIR"
echo Copy CUDA include and lib files to $PWD/cuda
mkdir cuda
cp -R -f "$CUDA_PATH/include" "$BUILD_DIR/cuda/include"
cp -R -f "$CUDA_PATH/lib" "$BUILD_DIR/cuda/lib"
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