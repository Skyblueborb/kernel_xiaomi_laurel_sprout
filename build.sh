#!/bin/bash

# Define variables
CLANG_VER="clang-r498229b"
ROM_PATH="/mnt/QuickBoi/LineageOS/21"

# Check if CLANG_DIR exists, if not try alternative paths
if [ -d "$ROM_PATH/prebuilts/clang/host/linux-x86/$CLANG_VER" ]; then
    CLANG_DIR="$ROM_PATH/prebuilts/clang/host/linux-x86/$CLANG_VER"
elif [ -d "$HOME/toolchains/neutron-clang" ]; then
    CLANG_DIR="$HOME/toolchains/neutron-clang"
else
    echo "Could not find the specified clang directory."
    exit 1
fi

echo "Using clang directory: $CLANG_DIR"


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

echo -e "***********************************************"
echo    "          Compiling Void Kernel                "
echo -e "***********************************************"

# Finally build it
mkdir -p out
make O=out ARCH=arm64 vendor/laurel_sprout-perf_defconfig
make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$CLANG_DIR/bin/llvm- LLVM=1 LLVM_IAS=1 Image.gz-dtb dtbo.img || exit

echo -e "***********************************************"
echo    "                Zipping Kernel                 "
echo -e "***********************************************"

# Create the flashable zip
cp out/arch/arm64/boot/Image.gz-dtb $Anykernel_DIR
cp out/arch/arm64/boot/dtbo.img $Anykernel_DIR
cd $Anykernel_DIR
zip -r9 $FINAL_ZIP.zip * -x .git README.md *placeholder

echo -e "***********************************************"
echo    "                 Cleaning up                   "
echo -e "***********************************************"

# Cleanup again
cd ../
rm -rf $Anykernel_DIR/Image.gz-dtb
rm -rf $Anykernel_DIR/dtbo.img
# rm -rf out

# Build complete
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$green Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$default"
