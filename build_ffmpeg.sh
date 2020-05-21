./configure --prefix=./josh_build \
  --disable-ffplay \
  --disable-doc \
  --disable-gpl \
  --enable-version3 \
  --disable-w32threads \
  --enable-static \
  --disable-shared \
  --disable-fontconfig \
  --disable-libfreetype \
  --disable-libmp3lame \
  --disable-libopenjpeg \
  --disable-libopus \
  --disable-libtheora \
  --disable-libvorbis \
  --disable-libvpx \
  --disable-libx264 \
  --disable-libx265 \
  --disable-libxvid \
  --disable-sdl2 \
  --disable-securetransport \
  --disable-lzma

make
make install
