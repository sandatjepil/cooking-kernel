#!/bin/bash
TOTAL_START=$(date +"%s")
export TZ="Asia/Jakarta"
source variables.sh
source clone.sh

# Additional command (if you're lazy to commit :v)
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Heliasts-Κασσιόπεια"/g' "$CONFIGPATHS"
sed -i 's/CONFIG_LTO_NONE=.*/CONFIG_LTO_CLANG=y/g' "$CONFIGPATHS"

# Speed up build process
MAKE="./makeparallel"

# Now building process is a function
start_cooking() {
	tg_edit "${ISIPESAN}${BUILDPROG}"

	FINAL_ZIP="$KERNELNAME-$1-$KERVER-$ZIPDATE"
	
	case $1 in
		KSU)
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=y/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=n/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=n/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=n/g' "$CONFIGPATHS"
			BONUS_MSG="*Note:* KernelSU switched to KernelSU-Next! 🤫 
[Download KSU-Next Manager]($KSUMGRLINK)"
			;;
		NoKSU)
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=y/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=y/g' "$CONFIGPATHS"
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=y/g' "$CONFIGPATHS"
			BONUS_MSG="*Note*: KernelSU disabled version, enjoy your legacy rooting method! 🤫"
			;;
		*)
			tg_post_msg "what do you want me to do? 😳"
			exit 1
			;;
	esac

	# Clean Up Output Directory
	[[ -d "$KERNELDIR"/out ]] && rm -rf "$KERNELDIR"/out
	
	BUILD_START=$(date +"%s")
	log info "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
	log info "***********************************************"
	log info "          BUILDING KERNEL          "
	log info "***********************************************"
	make $KERNEL_DEFCONFIG O=out 2>&1 | tee -a build.log

	make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=1 \
    LD="$KERNELDIR/clang/bin/ld.lld" \
	CC="$KERNELDIR/clang/bin/clang" \
	HOSTCC="$KERNELDIR/clang/bin/clang" \
	HOSTCXX="$KERNELDIR/clang/bin/clang++" \
	AR="$KERNELDIR/clang/bin/llvm-ar" \
	NM="$KERNELDIR/clang/bin/llvm-nm" \
	STRIP="$KERNELDIR/clang/bin/llvm-strip" \
	OBJCOPY="$KERNELDIR/clang/bin/llvm-objcopy" \
	OBJDUMP="$KERNELDIR/clang/bin/llvm-objdump" \
	CLANG_TRIPLE="$KERNELDIR/clang/bin/aarch64-linux-gnu-" \
	CROSS_COMPILE="$KERNELDIR/clang/bin/aarch64-linux-gnu-" \
	CROSS_COMPILE_COMPAT="$KERNELDIR/clang/bin/arm-linux-gnueabi-" \
    CROSS_COMPILE_ARM32="$KERNELDIR/clang/bin/arm-linux-gnueabi-" \
    2>&1 | tee -a build.log

	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	
	if ! [[ -f $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb ]];then
	    tg_post_build "build.log" "Compilation failed after $(($DIFF / 60)) minute(s) $(($DIFF % 60)) seconds"
	    log error "**** Compile Failed!!! ****"
	    TOTAL_END=$(date +"%s")
		TOTAL_DIFF=$(($TOTAL_END - $TOTAL_START))
		tg_post_msg "🚀 Total CI Operations: $(($TOTAL_DIFF / 60)) minute(s) $(($TOTAL_DIFF % 60)) seconds"

	    exit 1
	fi
	log info "**** Kernel build completed ****"
	
	log info "**** Copying Image.gz-dtb ****"
	cp -af $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb $AK3DIR
	
	BUILDPROG="Zipping build...."
	tg_edit "${ISIPESAN}${BUILDPROG}"

	log info "**** Time to zip up! ****"
	cd $AK3DIR
	zip -r9 ../$FINAL_ZIP.zip * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip
	cd $KERNELDIR
	
	if ! [[ -f $FINAL_ZIP.zip ]]; then
	    tg_post_build "$KERNELDIR/out/arch/arm64/boot/Image.gz-dtb" "Failed to zipping the kernel, Sending image file instead."
	    exit 1
	fi

	if [[ $SIGN == 1 ]]; then
		if which java > /dev/null 2>&1; then
			mv $FINAL_ZIP* krenul.zip
			if ! [[ -f zipsigner-3.0.jar ]]; then
				curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
			fi
			java -jar zipsigner-3.0.jar krenul.zip krenul-signed.zip 
			FINAL_ZIP+="-signed"
			mv krenul-signed.zip $FINAL_ZIP.zip
		else
			log error "Java not installed, abort signing zip..."
			SIGN=0
		fi
	fi
	
	MD5CHECK=$(md5sum "$FINAL_ZIP.zip" | cut -d' ' -f1)

	BUILDPROG="Zip done, Sending...."
	tg_edit "${ISIPESAN}${BUILDPROG}"

	log info "**** Uploading your zip now ****"
	tg_post_build "$FINAL_ZIP.zip" "⏳ *Compile Time*
- $(($DIFF / 60)) minute(s) $(($DIFF % 60)) seconds
📱 *Device*
- ${DEVICENAME}
🐧 *Kernel Version*
- ${KERVER}
🔥 *Supported Android Version*
- ${ANDRVER} ${ANDRVERTAG}
🛠 *Compiler*
- ${KBUILD_COMPILER_STRING}
💾 *MD5 Checksum*
- \`${MD5CHECK}\`
\`\`\`CHANGELOG
`git log --oneline -n1 | cut -d" " -f2-`\`\`\`

⚠️ ${BONUS_MSG}"

	# Removing zip files for second compilation
	rm -rf *.zip
}

case $WITHKSU in
	0)
		BUILDPROG="Compiling Without KSU...."
		start_cooking "NoKSU"
		;;
	1)
		BUILDPROG="Compiling With KSU...."
		start_cooking "KSU"
		;;
	b)
		BUILDPROG="Compiling With KSU...."
		start_cooking "KSU"
		BUILDPROG="Recompiling Without KSU...."
		start_cooking "NoKSU"
		;;
	*)
		tg_post_msg "what do you want me to do? 😳"
		;;
esac

if [[ $DEBUG == 1 ]]; then
  tg_post_build build.log ""
fi

TOTAL_END=$(date +"%s")
TOTAL_DIFF=$(($TOTAL_END - $TOTAL_START))
tg_post_msg "🚀 Total CI Operations: $(($TOTAL_DIFF / 60)) minute(s) $(($TOTAL_DIFF % 60)) seconds"