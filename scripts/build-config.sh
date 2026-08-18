#!/bin/bash

set -e

SCRIPTS_DIR="$( dirname -- "$0"; )"
BASE_DIR="$SCRIPTS_DIR/.."
SOURCES_DIR="$BASE_DIR/sources"
ARTIFACTS_DIR="$BASE_DIR/artifacts"

CONFIG_DIR="$ARTIFACTS_DIR/config"

rm -rf "$CONFIG_DIR/sane"
mkdir -p "$CONFIG_DIR/sane"
for f in $SOURCES_DIR/sane-backends/backend/*.conf; do
  cp "$f" "$CONFIG_DIR/sane/"
done
echo hpaio > $CONFIG_DIR/sane/hpaio.conf
echo hpaio >> $CONFIG_DIR/sane/dll.conf
rm -rf "$CONFIG_DIR/hp"
mkdir -p "$CONFIG_DIR/hp"
cp $SOURCES_DIR/hplip/COPYING "$ARTIFACTS_DIR/hplip-license.txt"

mkdir -p "$ARTIFACTS_DIR/data/hplip"
cp $SOURCES_DIR/hplip/data/models/models.dat $ARTIFACTS_DIR/data/hplip

cp "$SOURCES_DIR/libjpeg-turbo/LICENSE.md" "$ARTIFACTS_DIR/libjpeg-turbo-license.md"
cp "$SOURCES_DIR/libusb/COPYING" "$ARTIFACTS_DIR/libusb-license.txt"
cp "$SOURCES_DIR/libusb/AUTHORS" "$ARTIFACTS_DIR/libusb-authors.txt"
cp "$SOURCES_DIR/sane-backends/AUTHORS" "$ARTIFACTS_DIR/sane-backends-authors.txt"
cp "$SOURCES_DIR/sane-backends/LICENSE" "$ARTIFACTS_DIR/sane-backends-license.txt"