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
git config user.name  "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git reset --hard 28ff3ddb33a4451c1067de2cd77c1cd80e0fa734
git cherry-pick 853730f7c0498d43269b1eec7979ce260dad29bf a4d97d15cb6ae7f71b1e733177e7dfe1320c9635
git cherry-pick "233dfdc45c728ec7c9b02e234e752eae4175422d^..19dc4e7e1ec5bcdcceacd6436cabb8c4e7de1a7d"
git cherry-pick "b968a3785dfb99a36a97d1985a5a803ec08c0be1^..d8ef0834ac7aaf0c0ac71bd83f5c5334ea760a8a"
git cherry-pick 4acbdf374a97ff19f8d661a8ac8bd657152d07e5
git cherry-pick "79154484e0d888da7085450e2bc9a5d44ae6192e^..29c11298c8207f0846a528c633a902748c0048a9"
git cherry-pick "430a8340913f1f1ed0c4a6f156fd046abe7da838^..cb67f062d8fda4fa4199a8bc519a4e6156b9f910"
git cherry-pick "633cc751a86b9b5a7a0975aa13044b325492b513^..083ed0c977e85bffaee2696fe3762c5400d350be"

rm -rf KernelSU

# Set Kernelname
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Ἡλιαστής🏛"/g' arch/arm64/configs/X00TD_defconfig
# Disable Trace Printk
sed -i 's/CONFIG_TRACE_PRINTK=.*/CONFIG_TRACE_PRINTK=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
# Set ZRAM size to 2GB
sed -i 's/CONFIG_ZRAM_SIZE_OVERRIDE=.*/CONFIG_ZRAM_SIZE_OVERRIDE=2048/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig

git add . && git commit -m "Remove old KSU Residue"

# Revert Overclock Changes
# git revert -n 1aee30dc4098f50b6d19ea27ae71e97bfb7b970b 118f4dc55f68ab60a787b369ee91dc9c63bab9f8 3c93a9e685f4fd11945469e3bfe66eef2af7e833 5293e98e7632ec5c980b8604a85e008df077fb01 393fde8b7df4a3bc8a29061ee1ccfe6966d64bed 42642b4aedc45d2f42f7c86fb6872b0693e04ee2 0ebd3ac01279421990803392ab5c8763c7826d95
# git commit --allow-empty -m "[SQUASH] Use stock frequencies"

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
			# Revert old KSU Changes
			# git revert -n 5b5670a89aed43726c0d9762f4d2d029c4be1933 bc8e57e9c375943c13ee9ddff948181de2adfc44 6cb4375d5dc2b86e18ef76f51938cc423951be12 cef6d66ee45ca302213224a52bfe004a47961ec0 d06e68f80d50abc9e628b63fd12d59e8d224d8b6 3429f77d789c8131e81536fb94649d76e09803da f188048a96a5da9c34474406cde82a95831ff56d 1416387f9ba1d5b8424caef2ed4edfa5fb185cc6 0a76dc66dbeac814917650bf3623e96cb8c5ba9d 1345152b1939ac8ae19e4973f6abf32c6b16b965 5aaa1eb484991a8ff2b496641a76ea00c16cef16 c0a10c490d18107239e198649a892cbd189b48cf 0f570f37914d483132dfaa413fec2f51ededb36c
			# git commit --allow-empty -m "Revert Old KSU Things"

			# Apply patch Scope-minimized patch v1.6
			patch -p1 -N < ../kernelsuhook.patch || exit 1

			# Ambil Update KSU-N terbaru
			curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy
			git cherry-pick 5aaa1eb484991a8ff2b496641a76ea00c16cef16

			# Konfigurasi defconfig
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			echo "CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
" >> "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			
			# Commit perubahan yang ada agar masuk ke changelog
			current_tag=$(git -C "$KERNELDIR/KernelSU-Next" describe --tags --abbrev=0)
			git commit --allow-empty -m "KernelSU-Next: sync to $current_tag"
			
			BONUS_MSG="*Note:* KernelSU-Next updated to $current_tag 🤫
Check [KernelSU-Next release page](https://github.com/KernelSU-Next/KernelSU-Next/releases) to download the manager"
			;;
		NoKSU)
			# sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
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
    CROSS_COMPILE_ARM32="arm-linux-gnueabi-" 2>&1 | tee -a build.log

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
