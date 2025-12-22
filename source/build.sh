#!/bin/bash

# Define paths
SRC_DIR="osdata"
BUILD_DIR="build_tmp"
ISO_NAME="system.iso"

# 1. Clean up old builds
rm -rf $BUILD_DIR
rm -f $ISO_NAME
mkdir -p $BUILD_DIR

# 2. Compile from the osdata folder
nasm -f bin "$SRC_DIR/kernel.asm" -o "$BUILD_DIR/boot.img"

# 3. Pad the image to 1.44MB (Standard floppy size for ISO compatibility)
truncate -s 1440k "$BUILD_DIR/boot.img"

# 4. Create the ISO using xorriso
# -b tells it which file inside the ISO is the bootloader
xorriso -as mkisofs \
    -quiet \
    -V "II_OS" \
    -b boot.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -o "$ISO_NAME" \
    "$BUILD_DIR"

# 5. Optional: Remove the temporary build folder
# rm -rf $BUILD_DIR

echo "Build complete: $ISO_NAME"

# 6. Boot in QEMU
qemu-system-x86_64 -cdrom "$ISO_NAME"
