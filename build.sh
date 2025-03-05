#!/bin/bash
############################################################
[[ -f kernel/Makefile ]] || exit 1
cd kernel; export KERNELDIR=$(pwd) TZ="Asia/Jakarta"
blue='\033[0;34m'; red='\033[0;31m'; nocol='\033[0m'
log(){
	case $1 in
		info) echo -e "$blue$2$nocol";;
		warn) echo -e "$red$2$nocol";;
		*) echo -e "$red$2$nocol";;
	esac
}
############################################################
CONFIGFILE="$KERNELDIR"/arch/arm64/configs/vendor/X00TD_defconfig

# Additional command (if you're lazy to commit :v)
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Heliasts-Ἡλιαστής⚖️"/g' "$CONFIGFILE"

# Set the Variables
KERNELNAME="Heliasts"
DEVICENAME="Asus Zenfone Max Pro M1 (X00TD)"
ANDRVER="13-15"
ANDRVERTAG="(Tiramisu - Vanilla Ice Cream)"
KERVER=$(make kernelversion)
VARIANT="End Of Life"

# Set compiler
# 1 = Neutron Clang
# 2 = TheRagingBeast Clang
# 3 = ElectroWizard Clang
# 4 = RvClang
COMP=4

# Build with KSU?
# 1 = true || 0 = false
# b = build both KSU & Non-KSU
WITHKSU=1

# Sign the build?
# 1 = true || 0 = false
SIGN=1

############################################################
# Push to Telegram?
# 1 = true || 0 = false
PUSHTG=1
# TG_CHAT_ID=
# TG_TOKEN=

# Target telegram is a supergroup?
TG_SUPER=1
# TG_TOPIC_ID=

tg_post_msg(){
if [[ $PUSHTG == 1 ]]; then
	if [[ $TG_SUPER == 1 ]]; then
	    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
	    -d "message_thread_id=$TG_TOPIC_ID" -d "parse_mode=html" -d "text=$1" \
	    -d "chat_id=$TG_CHAT_ID" -d "disable_web_page_preview=true"
	else
		curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
		-d "chat_id=$TG_CHAT_ID" -d "disable_web_page_preview=true" \
		-d "parse_mode=html" -d "text=$1"
	fi
else
	log info "$1"
fi
}
tg_post_build() {
if [[ $PUSHTG == 1 ]]; then
	if [[ $TG_SUPER == 1 ]]; then
		curl -s "https://api.telegram.org/bot$TG_TOKEN/sendDocument" -F "document=@$1" \
		-F "chat_id=$TG_CHAT_ID" -F "disable_web_page_preview=true" \
		-F "parse_mode=Markdown" -F "caption=$2" -F "message_thread_id=$TG_TOPIC_ID"
	else
		curl -s "https://api.telegram.org/bot$TG_TOKEN/sendDocument" -F "document=@$1" \
		-F "chat_id=$TG_CHAT_ID" -F "disable_web_page_preview=true" \
		-F "parse_mode=Markdown" -F "caption=$2"
	fi
else
	log info "$2"
fi
}
############################################################

# Additional Variables
KERNEL_DEFCONFIG=vendor/X00TD_defconfig
DATE=$(date '+%d %m %Y') ZIPDATE=$(date '+%y%m%d%H%M')
export KBUILD_BUILD_TIMESTAMP=$(date) ARCH=arm64 SUBARCH=arm64

tg_post_msg "🕒 <b>`date '+%d %b %Y, %H:%M %Z'`</b>
Masterpiece creation starts! 
Version <b>$KERVER</b> for <b>$DEVICENAME</b>.
Crafted with <b>$(source /etc/os-release && echo "$NAME")</b>.
Compilation progress <a href='$CIRCLE_BUILD_URL'>click here!</a>."

log info "****Cloning Clang****"
case $COMP in
	1)
		mkdir -p clang && cd clang
		# Download antman and sync clang
		curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" -o antman && bash antman -S=latest
		# Create dummy elfedit so GNU binutils are picked from here
		if ! [[ -f aarch64-linux-gnu-elfedit ]]; then
			ln -s -p "aarch64-linux-gnu-ld" "aarch64-linux-gnu-elfedit"
		fi
		export PATH="$KERNELDIR/clang/bin:$PATH"
		cd $KERNELDIR
		[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
		;;
	2)
		git clone https://gitlab.com/varunhardgamer/trb_clang --depth=1 -qb 17 --single-branch clang || exit 1
		export PATH="$KERNELDIR/clang/bin:$PATH"
		;;
	3)
		# git clone https://gitlab.com/Tiktodz/electrowizard-clang.git --depth=1 -b 16 --single-branch clang || exit 1
		mkdir -p "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
		wget -qO ew.tar.gz https://github.com/Tiktodz/electrowizard-clang/releases/download/ElectroWizard-Clang-18.1.8-release/ElectroWizard-Clang-18.1.8.tar.gz && tar -xzf ew.tar.gz && rm -f ew.tar.gz && cd $KERNELDIR
		export PATH="$KERNELDIR/clang/bin:$PATH"
		[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
		;;
	4)
		# mkdir -p "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
		wget -qO rvclang.tar.gz https://github.com/Rv-Project/RvClang/releases/download/20.1.0/RvClang-20.1.0-bolt-pgo-full_lto.tar.gz && tar -xzf rvclang.tar.gz && rm -f rvclang.tar.gz && mv RvClang clang
		export PATH="$KERNELDIR/clang/bin:$PATH"
		[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
		;;
	*)
		tg_post_msg "Clang unavailable! Aborting..."
		exit 1
		;;
esac

export KBUILD_COMPILER_STRING=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

log info "****Generating Changelog****"
echo "<b><#selectbg_g>$(date)</#></b>" > changelog
git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A) "</*>"}' >> changelog
echo "" >> changelog
echo "<b><#selectbg_g>Aroma Installer config by: @ItsRyuujiX</#></b>" >> changelog

log info "**** AnyKernel3 Time ****"
AK3DIR=$KERNELDIR/AnyKernel3
if ! git clone -qb zeus --depth=1 https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	log warn "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	exit 1
fi

cd "$AK3DIR"
cp -af "$KERNELDIR"/changelog "$AK3DIR"/META-INF/com/google/android/aroma/changelog.txt
mv -f anykernel-real.sh anykernel.sh
sed -i "s/kernel.string=.*/kernel.string=$KERNELNAME/g" anykernel.sh
sed -i "s/kernel.type=.*/kernel.type=Stock/g" anykernel.sh
sed -i "s/kernel.for=.*/kernel.for=$DEVICENAME/g" anykernel.sh
sed -i "s/kernel.compiler=.*/kernel.compiler=$KBUILD_COMPILER_STRING/g" anykernel.sh
sed -i "s/kernel.made=.*/kernel.made=$KBUILD_BUILD_USER/g" anykernel.sh
sed -i "s/kernel.version=.*/kernel.version=$KERVER/g" anykernel.sh
sed -i "s/message.word=.*/message.word=Kernel need some time to settle./g" anykernel.sh
sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
sed -i "s/build.type=.*/build.type=$VARIANT/g" anykernel.sh
sed -i "s/supported.versions=.*/supported.versions=$ANDRVER/g" anykernel.sh
sed -i "s/device.name1=.*/device.name1=X00TD/g" anykernel.sh
sed -i "s/device.name2=.*/device.name2=X00T/g" anykernel.sh
sed -i "s/device.name3=.*/device.name3=Zenfone Max Pro M1 (X00TD)/g" anykernel.sh
sed -i "s/device.name4=.*/device.name4=ASUS_X00TD/g" anykernel.sh
sed -i "s/device.name5=.*/device.name5=ASUS_X00T/g" anykernel.sh
sed -i "s/X00TD=.*/X00TD=1/g" anykernel.sh

cd $AK3DIR/META-INF/com/google/android
sed -i "s/KNAME/$KERNELNAME/g" aroma-config
sed -i "s/KVER/$KERVER/g" aroma-config
sed -i "s/KAUTHOR/$KBUILD_BUILD_USER/g" aroma-config
sed -i "s/KDEVICE/Zenfone Max Pro M1/g" aroma-config
sed -i "s/KBDATE/$DATE/g" aroma-config
sed -i "s/KVARIANT/$VARIANT/g" aroma-config
cd "$KERNELDIR"
log info "***** AnyKernel3 Done! *****"

# Speed up build process
MAKE="./makeparallel"

# Now building process is a function
start_cooking() {
	FINAL_ZIP="$KERNELNAME-$1-$KERVER-$ZIPDATE"
	
	case $1 in
		KSU)
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=y/g' "$CONFIGFILE"
			# sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=n/g' "$CONFIGFILE"
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=n/g' "$CONFIGFILE"
			# sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=n/g' "$CONFIGFILE"
			BONUS_MSG="*Note:* KernelSU switched to KernelSU-Next! 🤫 https://github.com/KernelSU-Next/KernelSU-Next/releases"
			;;
		NoKSU)
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$CONFIGFILE"
			# sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=y/g' "$CONFIGFILE"
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=y/g' "$CONFIGFILE"
			# sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=y/g' "$CONFIGFILE"
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
	make $KERNEL_DEFCONFIG O=out 2>&1 | tee -a error.log
	case $COMP in
		1)
			make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=0 \
		    LD="$KERNELDIR/clang/bin/ld.lld" \
			CC="$KERNELDIR/clang/bin/clang" \
			HOSTCC="$KERNELDIR/clang/bin/clang" \
			HOSTCXX="$KERNELDIR/clang/bin/clang++" \
			AR="$KERNELDIR/clang/bin/llvm-ar" \
			NM="$KERNELDIR/clang/bin/llvm-nm" \
			STRIP="$KERNELDIR/clang/bin/llvm-strip" \
			OBJCOPY="$KERNELDIR/clang/bin/llvm-objcopy" \
			OBJDUMP="$KERNELDIR/clang/bin/llvm-objdump" \
			CROSS_COMPILE="$KERNELDIR/clang/bin/aarch64-linux-gnu-" \
		    CROSS_COMPILE_ARM32="$KERNELDIR/clang/bin/arm-linux-gnueabi-" 2>&1 | tee -a error.log
		    ;;
		4)
			make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=0 \
		    LD="$KERNELDIR/clang/bin/ld.lld" \
			CC="$KERNELDIR/clang/bin/clang" \
			HOSTCC="$KERNELDIR/clang/bin/clang" \
			HOSTCXX="$KERNELDIR/clang/bin/clang++" \
			AR="$KERNELDIR/clang/bin/llvm-ar" \
			NM="$KERNELDIR/clang/bin/llvm-nm" \
			STRIP="$KERNELDIR/clang/bin/llvm-strip" \
			OBJCOPY="$KERNELDIR/clang/bin/llvm-objcopy" \
			OBJDUMP="$KERNELDIR/clang/bin/llvm-objdump" \
			CROSS_COMPILE="$KERNELDIR/clang/bin/aarch64-linux-gnu-" \
		    CROSS_COMPILE_ARM32="$KERNELDIR/clang/bin/arm-linux-gnueabi-" 2>&1 | tee -a error.log
		    ;;
		*)
		    make -j$(nproc --all) O=out LLVM=1 \
		    LD="$KERNELDIR/clang/bin/ld.lld" \
			CC="$KERNELDIR/clang/bin/clang" \
			HOSTCC="$KERNELDIR/clang/bin/clang" \
			HOSTCXX="$KERNELDIR/clang/bin/clang++" \
			AR="$KERNELDIR/clang/bin/llvm-ar" \
			NM="$KERNELDIR/clang/bin/llvm-nm" \
			STRIP="$KERNELDIR/clang/bin/llvm-strip" \
			OBJCOPY="$KERNELDIR/clang/bin/llvm-objcopy" \
			OBJDUMP="$KERNELDIR/clang/bin/llvm-objdump" \
			CLANG_TRIPLE="aarch64-linux-gnu-" \
			CROSS_COMPILE="$KERNELDIR/clang/bin/clang" \
		    CROSS_COMPILE_COMPAT="$KERNELDIR/clang/bin/clang" \
		    CROSS_COMPILE_ARM32="$KERNELDIR/clang/bin/clang" 2>&1 | tee -a error.log
		    ;;
	esac

	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	
	if ! [[ -f $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb ]];then
	    tg_post_build "error.log" "Compile failed!!"
	    log warn "**** Compile Failed!!! ****"
	    exit 1
	fi
	log info "**** Kernel build completed ****"
	
	log info "**** Copying Image.gz-dtb ****"
	cp -af $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb $AK3DIR
	
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
			log warn "Java not installed, abort signing zip..."
			SIGN=0
		fi
	fi
	
	MD5CHECK=$(md5sum "$FINAL_ZIP.zip" | cut -d' ' -f1)

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
		start_cooking "NoKSU"
		;;
	1)
		start_cooking "KSU"
		;;
	b)
		start_cooking "KSU"
		start_cooking "NoKSU"
		;;
	*)
		tg_post_msg "what do you want me to do? 😳"
		;;
esac
