#!/bin/bash

function kernel() {
    local fn="${1}"
    target="${2}"

    if [[ "$fn" = c ]] || [[ "$fn" = cc ]]; then
    if [ ! -d ~/kernel ]; then
         echo "Wrong dir to compile kernel"
         return
    fi
    if [ ! -d ~/kernel/toolchain ]; then
         git clone https://github.com/SagarMakhar/toolchain ~/kernel/toolchain
    fi
    fi

    if [ ! -d ~/kernel/AnyKernel3 ]; then
         git clone https://github.com/SagarMakhar/AnyKernel3 ~/kernel/AnyKernel3
    fi

    case $fn in
        "clang"|"cc")
            compileclang $target
        ;;
        "compile"|"c")
            compile $target
        ;;
        "upload"|"u")
            upload $target
        ;;
        *)
            echo "USE : kernel <c/cc|u> or <compile/clang|upload>"
        ;;
    esac

}

function compile() {
    t="${1}"
    export CROSS_COMPILE=/home/babu/kernel/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-
    export CROSS_COMPILE_ARM32=/home/babu/kernel/toolchain/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
    export ARCH=arm64 && export SUBARCH=arm64
    make "$t"_defconfig O=out/
   # make RMX1971_defconfig O=out/
    make -j32 O=out/ 2>&1 | tee log.txt
}

function compileclang() {
    # Path to executables in Clang toolchain
    clang_bin="/home/babu/kernel/toolchain/linux-x86/clang-r370808/bin"

    # 64-bit GCC toolchain prefix
    gcc_prefix64="/home/babu/kernel/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-"

    # 32-bit GCC toolchain prefix
    gcc_prefix32="/home/babu/kernel/toolchain/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

    export LD_LIBRARY_PATH="$clang_bin/../lib:$clang_bin/../lib64:$LD_LIBRARY_PATH"
    export PATH="$clang_bin:$PATH"

    make_flags=(
        -j"$(nproc --all)"
        ARCH="arm64"
        O="out"
        CC="clang"
        AR="llvm-ar"
        NM="llvm-nm"
        OBJCOPY="llvm-objcopy"
        OBJDUMP="llvm-objdump"
        STRIP="llvm-strip"
        CROSS_COMPILE="$gcc_prefix64"
        CROSS_COMPILE_ARM32="$gcc_prefix32"
        CLANG_TRIPLE="aarch64-linux-gnu-"
    )

    make "${make_flags[@]}" $1_defconfig
    make "${make_flags[@]}"
}

function upload() {
    local c="${1}"
[[ -z "${c}" ]] && c="me"
    if [ -f "./kernel" ]; then
         cp kernel ~/kernel/AnyKernel3
         rm -rf ~/kernel/AnyKernel3/z*
         mv ~/kernel/AnyKernel3/kernel  ~/kernel/AnyKernel3/zImage-dtb
         cd ~/kernel/AnyKernel3
         rm -rf *.zip
         zip -r kernel.zip *
         gupbot $c kernel.zip
         cd -
    elif [ -f "./out/arch/arm64/boot/Image.gz-dtb" ]; then
         rm -rf ~/kernel/AnyKernel3/zImage-dtb
     mv out/arch/arm64/boot/Image.gz-dtb ~/kernel/AnyKernel3/zImage-dtb
     cd ~/kernel/AnyKernel3
         rm -rf *.zip
         zip -r kernel.zip *
     gupbot $c kernel.zip
     cd -
    else
         echo "kernel not found to upload"
    fi
}


