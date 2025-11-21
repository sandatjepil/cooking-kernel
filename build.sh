#!/usr/bin/env bash
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

# Additional command (if you're lazy to commit :v)
# Set Kernelname
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Ἡλιαστής🏛"/g' arch/arm64/configs/X00TD_defconfig
# Disable Trace Printk
sed -i 's/CONFIG_TRACE_PRINTK=.*/CONFIG_TRACE_PRINTK=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig

# Set the Variables
KERNELNAME="Heliasts"
DEVICENAME="Asus Zenfone Max Pro M1 (X00TD)"
ANDRVER="9-13"
ANDRVERTAG="(Pie - Tiramisu)"
KERVER=$(make kernelversion)
VARIANT="End Of Life"

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
KERNEL_DEFCONFIG=X00TD_defconfig
DATE=$(date '+%d %m %Y') ZIPDATE=$(date '+%y%m%d%H%M')
export KBUILD_BUILD_TIMESTAMP=$(date) ARCH=arm64 SUBARCH=arm64

tg_post_msg "🕒 <b>`date '+%d %b %Y, %H:%M %Z'`</b>
Masterpiece creation starts! 
Version <b>$KERVER</b> for <b>$DEVICENAME</b>.
Crafted with <b>$(source /etc/os-release && echo "$NAME")</b>.
Compilation progress <a href='$CIRCLE_BUILD_URL'>click here!</a>."

log info "****Cloning Clang****"
TC_EXT="$KERNELDIR/toolchain"
mkdir -p "$TC_EXT" && pushd "$TC_EXT"
wget -qO clang.tar.zst $(curl -sL https://raw.githubusercontent.com/PurrrsLitterbox/LLVM-stable/refs/heads/main/latestlink.txt) && tar -xf clang.tar.zst && rm -f clang.tar.zst
popd
export PATH="$TC_EXT/bin:$PATH"
[[ -f "$TC_EXT/bin/clang" ]] || exit 1

# export KBUILD_COMPILER_STRING=$("$TC_EXT/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

log info "**** AnyKernel3 Time ****"
AK3DIR=$KERNELDIR/AnyKernel3
if ! git clone -qb four4-hmp --depth=1 https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	log warn "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	exit 1
fi

cd "$AK3DIR"
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
mv -f update-binary update-binary-installer
mv -f aroma-binary update-binary
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
			# Update KSU-Next Otomatis
			# Fetch tags dari remote
			git -C "$KERNELDIR/KernelSU" fetch --tags --quiet
			current_tag=$(git -C "$KERNELDIR/KernelSU" describe --tags --abbrev=0)
			latest_tag=$(git -C "$KERNELDIR/KernelSU" tag --sort=-v:refname | head -n 1)

			if [[ "$current_tag" != "$latest_tag" ]]; then
			    log info "🚀 KSU-Next versi baru tersedia: $latest_tag (saat ini $current_tag)"
			    git -C "$KERNELDIR/KernelSU" checkout --quiet "$latest_tag"
			    current_tag=$(git -C "$KERNELDIR/KernelSU" describe --tags --abbrev=0)
			else
			    log info "KSU-Next Sudah di versi terbaru."
			fi

			# Konfigurasi defconfig
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=y/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			
			# Commit perubahan yang ada agar masuk ke changelog
			git config user.name  "github-actions[bot]"
			git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
			git add KernelSU && git commit --amend -m "KernelSU-Next: sync to $current_tag"
			
			BONUS_MSG="*Note:* KernelSU-Next updated to $current_tag 🤫
Check [KernelSU-Next release page](https://github.com/KernelSU-Next/KernelSU-Next/releases) to download the manager"
			;;
		NoKSU)
			sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=y/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=y/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=y/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			BONUS_MSG="*Note*: KernelSU disabled version, enjoy your legacy rooting method (p.s. APatch is now supported!) 🤫"
			;;
		*)
			tg_post_msg "what do you want me to do? 😳"
			exit 1
			;;
	esac

	# Changelog otomatis
	log info "****Generating Changelog****"
	echo "<b><#selectbg_g>$(date)</#></b>" > changelog
	git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A) "</*>"}' >> changelog
	echo "" >> changelog
	echo "<b><#selectbg_g>Aroma Installer config by: @ItsRyuujiX</#></b>" >> changelog
	cp -af "$KERNELDIR"/changelog "$AK3DIR"/META-INF/com/google/android/aroma/changelog.txt

	# Clean Up Output Directory
	[[ -d "$KERNELDIR"/out ]] && rm -rf "$KERNELDIR"/out
	
	BUILD_START=$(date +"%s")
	log info "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
	log info "***********************************************"
	log info "          BUILDING KERNEL          "
	log info "***********************************************"
	make $KERNEL_DEFCONFIG \
	CC=clang \
	LD=ld.lld \
	O=out 2>&1 | tee -a build.log

	make -j4 O=out LLVM=1 LLVM_IAS=0 \
    LD="ld.lld" \
	CC="clang" \
	HOSTCC="clang" \
	HOSTCXX="clang++" \
	AR="llvm-ar" \
	NM="llvm-nm" \
	STRIP="llvm-strip" \
	OBJCOPY="llvm-objcopy" \
	OBJDUMP="llvm-objdump" \
	CROSS_COMPILE="aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="arm-linux-gnueabi-" 2>&1 | tee -a build.log | grep -iE "(warning|error)"

	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	
	if ! [[ -f $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb ]];then
	    tg_post_build "build.log" "Compile failed!!"
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
}

case $WITHKSU in
	0)
		start_cooking "NoKSU"
		;;
	1)
		start_cooking "KSU"
		;;
	b)
		start_cooking "NoKSU"
		# Removing zip files for second compilation
		rm -rf *.zip
		start_cooking "KSU"
		;;
	*)
		tg_post_msg "what do you want me to do? 😳"
		;;
esac
