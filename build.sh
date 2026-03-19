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
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Heliasts-Cassiopheia"/g' arch/arm64/configs/X00TD_defconfig
# Disable Trace Printk
sed -i 's/CONFIG_TRACE_PRINTK=.*/CONFIG_TRACE_PRINTK=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
sed -i 's/CONFIG_ZRAM_SIZE_OVERRIDE=.*/CONFIG_ZRAM_SIZE_OVERRIDE=1024/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig

git commit -am "[SQUASH] Use stock frequencies"

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

build_fail() {
if [ -f build.log ]; then
    tg_post_build "build.log" "Compile failed!!"
else
    tg_post_msg "Compile failed without even started, <a href='$CIRCLE_BUILD_URL'>click here!</a>"
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
[[ -f "$TC_EXT/bin/clang" ]] || build_fail

# export KBUILD_COMPILER_STRING=$("$TC_EXT/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

log info "**** AnyKernel3 Time ****"
AK3DIR=$KERNELDIR/AnyKernel3
if ! git clone -qb four4-hmp --depth=1 https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	log warn "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	build_fail
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
            # Ambil Update xxKSU terbaru
            KSU_VERSION="$(git ls-remote --tags https://github.com/backslashxx/KernelSU.git | grep -oP "v\d+\.\d+\.\d+(-\w+)?" | sort -V | tail -n 1)"
            curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/refs/heads/master/kernel/setup.sh" | bash -s "$KSU_VERSION"
            git cherry-pick 5aaa1eb484991a8ff2b496641a76ea00c16cef16
            pushd KernelSU
            patch -p1 -N < ../../ksuver.patch
            popd                        
            KSU_VERSION=$(git -C "$KERNELDIR/KernelSU" describe --tags --abbrev=0)
            export KCFLAGS='-DKSU_VERSION_TAG=\"'"$KSU_VERSION"'\"'
            BONUS_MSG="*Note:* KernelSU updated to xxKSU version $KSU_VERSION 🤫
Check [xxKSU release page](https://github.com/backslashxx/KernelSU/releases) to download the manager"

			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			echo "
CONFIG_KSU=y
CONFIG_KSU_TAMPER_SYSCALL_TABLE=y
" >> "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
			
			# Commit perubahan yang ada agar masuk ke changelog
			git add KernelSU && git commit -m "KernelSU-Next: sync to $KSU_VERSION"
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
			build_fail
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
	    build_fail
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
	    build_fail
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
