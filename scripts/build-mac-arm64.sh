#!/bin/bash

set -e

SCRIPTS_DIR="$( dirname -- "$0"; )"
BASE_DIR="$SCRIPTS_DIR/.."
SOURCES_DIR="$BASE_DIR/sources"
ARTIFACTS_DIR="$BASE_DIR/artifacts"

TARGET_DIR="$ARTIFACTS_DIR/mac-arm64"

PROCESS_LIBUSB=1
PROCESS_LIBJPEG=1
PROCESS_SANE=1
PROCESS_HPLIP=1

if [ $PROCESS_LIBUSB -eq 1 ]; then
pushd "$SOURCES_DIR/libusb"
./autogen.sh
CXXFLAGS="-mmacosx-version-min=11.0" CFLAGS="-mmacosx-version-min=11.0" ./configure
make clean
make -j$(nproc)
popd
fi

if [ $PROCESS_LIBJPEG -eq 1 ]; then
pushd "$SOURCES_DIR/libjpeg-turbo"
rm -rf build
mkdir build
pushd "build"
cmake .. -G"Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
cmake --build . --parallel $(nproc)
popd
popd
fi

if [ $PROCESS_SANE -eq 1 ]; then
pushd "$SOURCES_DIR/sane-backends"
./autogen.sh
LDFLAGS="-L$( realpath "../libjpeg-turbo/build"; ) -L$( realpath "../libusb/libusb/.libs"; )" \
CPPFLAGS="-I$( realpath "../libjpeg-turbo"; ) -I$( realpath "../libjpeg-turbo/build"; ) -I$( realpath "../libusb/libusb"; )" \
CXXFLAGS="-mmacosx-version-min=11.0" CFLAGS="-mmacosx-version-min=11.0" \
./configure
make clean
make
popd
fi

pushd "$SOURCES_DIR/hplip"
if true; then
[ -f ./configure ] || { libtoolize && aclocal && autoupdate && autoconf && automake --add-missing; }
LDFLAGS="-L$( realpath "../libjpeg-turbo/build"; ) -L$( realpath "../libusb/libusb/.libs"; ) -L$( realpath "../sane-backends/backend/.libs"; )" \
CPPFLAGS="-I$( realpath "../libjpeg-turbo"; ) -I$( realpath "../libjpeg-turbo/build"; ) -I$( realpath "../libusb/libusb"; ) -I$( realpath "../libusb"; ) -Wno-implicit-function-declaration" \
CXXFLAGS="-mmacosx-version-min=11.0" CFLAGS="-mmacosx-version-min=11.0" \
./configure --enable-lite-build --disable-hpcups-install --disable-hpps-install --disable-hppgsz-build --disable-gui-build --disable-fax-build --disable-cups-drv-install --disable-dbus-build --with-macos-app-modelsdir=_data/hplip
make clean
make -j8
fi
#make install DESTDIR=$( realpath "$TARGET_DIR/hplib"; )
popd

if [ $PROCESS_LIBUSB -eq 1 ]; then
  cp "$SOURCES_DIR/libusb/libusb/.libs/libusb-1.0.0.dylib" "$TARGET_DIR/libusb-1.0.0.dylib"
fi

if [ $PROCESS_LIBJPEG -eq 1 ]; then
  cp "$SOURCES_DIR/libjpeg-turbo/build/libjpeg.62.dylib" "$TARGET_DIR/libjpeg.62.dylib"
fi

if [ $PROCESS_SANE -eq 1 ]; then
cp "$SOURCES_DIR/sane-backends/backend/.libs/libsane.1.dylib" "$TARGET_DIR/libsane.1.dylib"
rm -rf "$TARGET_DIR/sane"
mkdir "$TARGET_DIR/sane"
for f in $SOURCES_DIR/sane-backends/backend/.libs/libsane-*.so; do
  [[ $f != *.1.so ]] && continue
  cp "$f" "$TARGET_DIR/sane/"
done
fi

cp "$SOURCES_DIR/hplip/.libs/libhpmud.0.dylib" "$TARGET_DIR/"
cp "$SOURCES_DIR/hplip/.libs/libhpip.0.dylib" "$TARGET_DIR/"
cp "$SOURCES_DIR/hplip/.libs/libhpdiscovery.0.dylib" "$TARGET_DIR/"
cp "$SOURCES_DIR/hplip/.libs/libsane-hpaio.1.so" "$TARGET_DIR/sane/libsane-hpaio.1.so"
[ -d "$TARGET_DIR/data/hplip" ] || mkdir -p "$TARGET_DIR/data/hplip"

