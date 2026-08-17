#!/bin/bash

# Apply the local patches to the source submodules. Idempotent: a patch that
# is already present in the tree (e.g. on a dev machine where the changes
# live uncommitted in the submodule) is skipped.

set -e

SCRIPTS_DIR="$( dirname -- "$0"; )"
BASE_DIR="$SCRIPTS_DIR/.."
SOURCES_DIR="$BASE_DIR/sources"
PATCHES_DIR="$( realpath "$BASE_DIR/patches"; )"

apply_patch() {
  local submodule="$1"
  local patch="$2"
  if git -C "$SOURCES_DIR/$submodule" apply --check "$PATCHES_DIR/$patch" 2>/dev/null; then
    git -C "$SOURCES_DIR/$submodule" apply "$PATCHES_DIR/$patch"
    echo "applied $patch to sources/$submodule"
  elif git -C "$SOURCES_DIR/$submodule" apply --check --reverse "$PATCHES_DIR/$patch" 2>/dev/null; then
    echo "skipped $patch (already applied to sources/$submodule)"
  else
    echo "ERROR: $patch does not apply to sources/$submodule" >&2
    exit 1
  fi
}

apply_patch libusb libusb-macfix.patch
apply_patch sane-backends sane-streamdevices.patch
