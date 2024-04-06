#!/bin/bash

# Define colors
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
CYAN="\e[1;36m"
DEFAULT="\e[0m"

# Define variables
CLANG_VER="clang-r498229b"
ROM_PATH="/mnt/QuickBoi/LineageOS/21"

# Check if CLANG_DIR exists, if not try alternative paths
if [ -d "$ROM_PATH/prebuilts/clang/host/linux-x86/$CLANG_VER" ]; then
    CLANG_DIR="$ROM_PATH/prebuilts/clang/host/linux-x86/$CLANG_VER"
elif [ -d "$HOME/toolchains/neutron-clang" ]; then
    CLANG_DIR="$HOME/toolchains/neutron-clang"
else
    echo -e "${RED}Could not find the specified clang directory.${DEFAULT}"
    exit 1
fi

echo -e "${YELLOW}Using clang directory: $CLANG_DIR${DEFAULT}"


KERNEL_DIR=$PWD
Anykernel_DIR=$KERNEL_DIR/AnyKernel3/
DATE=$(date +"[%d%m%Y]")
TIME=$(date +"%H.%M.%S")
KERNEL_NAME="Void"
DEVICE="laurel_sprout"
FINAL_ZIP="$KERNEL_NAME"-"$DEVICE"-"$DATE"

BUILD_START=$(date +"%s")

# Export variables
export TARGET_KERNEL_CLANG_COMPILE=true
PATH="$CLANG_DIR/bin:${PATH}"

echo -e "${CYAN}***********************************************${DEFAULT}"
echo -e "${CYAN}          Compiling Void Kernel                ${DEFAULT}"
echo -e "${CYAN}***********************************************${DEFAULT}"

# Finally build it
mkdir -p out
make O=out ARCH=arm64 vendor/laurel_sprout-perf_defconfig
make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$CLANG_DIR/bin/llvm- LLVM=1 LLVM_IAS=1 Image.gz-dtb dtbo.img || exit

echo -e "${CYAN}***********************************************${DEFAULT}"
echo -e "${CYAN}                Zipping Kernel                 ${DEFAULT}"
echo -e "${CYAN}***********************************************${DEFAULT}"

# Create the flashable zip
cp out/arch/arm64/boot/Image.gz-dtb $Anykernel_DIR
cp out/arch/arm64/boot/dtbo.img $Anykernel_DIR
cd $Anykernel_DIR
rm *.zip
zip -r9 $FINAL_ZIP.zip * -x .git README.md *placeholder

echo -e "${CYAN}***********************************************${DEFAULT}"
echo -e "${CYAN}                 Cleaning up                   ${DEFAULT}"
echo -e "${CYAN}***********************************************${DEFAULT}"

# Cleanup again
cd ../
rm -rf $Anykernel_DIR/Image.gz-dtb
rm -rf $Anykernel_DIR/dtbo.img
# rm -rf out

# Build complete
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "${GREEN}Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.${DEFAULT}"
