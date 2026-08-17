#!/bin/bash

set -e

SCRIPTS_DIR="$( dirname -- "$0"; )"
BASE_DIR="$SCRIPTS_DIR/.."
SOURCES_DIR="$BASE_DIR/sources"
ARTIFACTS_DIR="$BASE_DIR/artifacts"

TARGET_DIR="$ARTIFACTS_DIR/mac-x64"

JOBS="$( nproc 2>/dev/null || sysctl -n hw.ncpu )"

# Drop everything configure/autoreconf generated, before regenerating it.
# 'make clean' is not enough: it keeps config.status, the config.h it produced
# and the stamp-hN files that make uses to decide the header is up to date. A
# stale or half-written config.h then survives into the next build, and make
# never regenerates it. In sane-backends that shows up as a config.h still
# carrying the '#undef HAVE_U_CHAR' template defaults, which turns u_char into
# a macro and makes <sys/types.h> fail to compile.
distclean_tree() {
  [ -f Makefile ] && { make distclean || true; }
  rm -f config.status config.cache
  rm -f "$@"
}

PROCESS_LIBUSB=1
PROCESS_LIBJPEG=1
PROCESS_SANE=1
PROCESS_HPLIP=1

if [ $PROCESS_LIBUSB -eq 1 ]; then
pushd "$SOURCES_DIR/libusb"
distclean_tree config.h stamp-h1
./autogen.sh
CXXFLAGS="-mmacosx-version-min=10.15 -arch x86_64" CFLAGS="-mmacosx-version-min=10.15 -arch x86_64" ./configure
make -j$JOBS
install_name_tool -id @rpath/libusb-1.0.0.dylib libusb/.libs/libusb-1.0.0.dylib
popd
fi

if [ $PROCESS_LIBJPEG -eq 1 ]; then
pushd "$SOURCES_DIR/libjpeg-turbo"
rm -rf build
mkdir build
pushd "build"
# CMAKE_POLICY_VERSION_MINIMUM: libjpeg-turbo's cmake_minimum_required(2.8.12)
# is rejected outright by CMake >= 4.
cmake .. -G"Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build . --parallel $JOBS
popd
popd
fi

if [ $PROCESS_SANE -eq 1 ]; then
pushd "$SOURCES_DIR/sane-backends"
distclean_tree include/sane/config.h include/sane/stamp-h1
./autogen.sh
LDFLAGS="-L$( realpath "../libjpeg-turbo/build"; ) -L$( realpath "../libusb/libusb/.libs"; )" \
CPPFLAGS="-I$( realpath "../libjpeg-turbo"; ) -I$( realpath "../libjpeg-turbo/build"; ) -I$( realpath "../libusb/libusb"; )" \
CXXFLAGS="-mmacosx-version-min=10.15 -arch x86_64" CFLAGS="-mmacosx-version-min=10.15 -arch x86_64" \
./configure
make -j$JOBS
install_name_tool -id @rpath/libsane.1.dylib backend/.libs/libsane.1.dylib
popd
fi

# hplip includes libusb headers as <libusb-1.0/libusb.h> and <libusb/libusb.h>;
# the in-tree libusb checkout has neither layout, so fake both with symlinks.
ln -sfn libusb "$SOURCES_DIR/libusb/libusb-1.0"
ln -sfn . "$SOURCES_DIR/libusb/libusb/libusb"

pushd "$SOURCES_DIR/hplip"
if true; then
distclean_tree config.h stamp-h1
[ -f ./configure ] || { glibtoolize && aclocal && autoupdate && autoconf && automake --add-missing; }
LDFLAGS="-L$( realpath "../libjpeg-turbo/build"; ) -L$( realpath "../libusb/libusb/.libs"; ) -L$( realpath "../sane-backends/backend/.libs"; )" \
CPPFLAGS="-I$( realpath "../libjpeg-turbo"; ) -I$( realpath "../libjpeg-turbo/build"; ) -I$( realpath "../libusb/libusb"; ) -I$( realpath "../libusb"; ) -Wno-implicit-function-declaration" \
CXXFLAGS="-mmacosx-version-min=10.15 -arch x86_64" CFLAGS="-mmacosx-version-min=10.15 -arch x86_64" \
./configure --enable-lite-build --disable-hpcups-install --disable-hpps-install --disable-hppgsz-build --disable-gui-build --disable-fax-build --disable-cups-drv-install --disable-dbus-build --with-macos-app-modelsdir=_data/hplip
make -j$JOBS
install_name_tool -id @rpath/libhpmud.0.dylib .libs/libhpmud.0.dylib
install_name_tool -id @rpath/libhpip.0.dylib .libs/libhpip.0.dylib
install_name_tool -id @rpath/libhpdiscovery.0.dylib .libs/libhpdiscovery.0.dylib
# libhpmud was linked before libhpdiscovery's install name was fixed
install_name_tool -change /usr/local/lib/libhpdiscovery.0.dylib @rpath/libhpdiscovery.0.dylib .libs/libhpmud.0.dylib
# libsane-hpaio was linked before any hplip install names were fixed
install_name_tool -change /usr/local/lib/libhpip.0.dylib @rpath/libhpip.0.dylib .libs/libsane-hpaio.1.so
install_name_tool -change /usr/local/lib/libhpmud.0.dylib @rpath/libhpmud.0.dylib .libs/libsane-hpaio.1.so
install_name_tool -change /usr/local/lib/libhpdiscovery.0.dylib @rpath/libhpdiscovery.0.dylib .libs/libsane-hpaio.1.so
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

