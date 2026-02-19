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

patch -p1 -N < ../zstd.patch
patch -p1 -N < ../zstd1.patch
patch -p1 -N < ../zstd2.patch
patch -p1 -N < ../zstd3.patch
patch -p1 -N < ../zstd4.patch
# patch -p1 -N < ../revert140mhz.patch || exit 1
cp -af ../Makefile ./
cp -af ../sweet_defconfig ./arch/arm64/configs/sweet_defconfig
git commit -am "[SQUASH] ZSTD: bump to version 1.5.5 & set ZSTD to default zram compression method"

# Set the Variables
KERNELNAME="Heliasts"
DEVICENAME="Redmi Note 10 Pro (sweet)"
ANDRVER="11-15"
ANDRVERTAG="(Red Velvet Cake - Vanilla Ice Cream)"
KERVER=$(make kernelversion)
VARIANT="End Of Life"
export KBUILD_BUILD_HOST="Litterbox"

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
KERNEL_DEFCONFIG=sweet_defconfig
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
wget -qO clang.tar.zst https://github.com/PurrrsLitterbox/LLVM-stable/releases/download/llvmorg-21.1.8/clang.tar.zst && tar -xf clang.tar.zst && rm -f clang.tar.zst
# wget -qO clang.tar.zst $(curl -sL https://raw.githubusercontent.com/PurrrsLitterbox/LLVM-stable/refs/heads/main/latestlink.txt) && tar -xf clang.tar.zst && rm -f clang.tar.zst
popd
export PATH="$TC_EXT/bin:$PATH"
[[ -f "$TC_EXT/bin/clang" ]] || exit 1

# export KBUILD_COMPILER_STRING=$("$TC_EXT/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

log info "**** AnyKernel3 Time ****"
AK3DIR=$KERNELDIR/AnyKernel3
if ! git clone -qb sweet --depth=1 https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	log warn "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	exit 1
fi

log info "***** AnyKernel3 Done! *****"

# Speed up build process
MAKE="./makeparallel"

# Now building process is a function
start_cooking() {
	FINAL_ZIP="$KERNELNAME-$1-$KERVER-$ZIPDATE"
	
	case $1 in
		KSU)
			# Ambil Update KSU-N terbaru
			patch -p1 -N < ../umount.patch || exit 1
			curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/refs/heads/master/kernel/setup.sh" | bash -s
			# git -C "KernelSU-Next" revert -n 21058f79bd5c0e57c96115dfa839a0c6fa839d69

			# Apply scope-minimized patch v1.6
			# patch -p1 -N < ../kernelsuhook.patch || exit 1
			
			current_tag=$(git -C "$KERNELDIR/KernelSU" describe --tags --abbrev=0)			
			BONUS_MSG="*Note:* KernelSU updated to xxKSU version $current_tag 🤫
Check [xxKSU release page](https://github.com/backslashxx/KernelSU/releases) to download the manager"
			;;
		NoKSU)
			# sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$KERNELDIR"/arch/arm64/configs/sweet_defconfig
			sed -i 's/CONFIG_KALLSYMS=.*/CONFIG_KALLSYMS=y/g' "$KERNELDIR"/arch/arm64/configs/sweet_defconfig
			sed -i 's/CONFIG_KALLSYMS_ALL=.*/CONFIG_KALLSYMS_ALL=y/g' "$KERNELDIR"/arch/arm64/configs/sweet_defconfig
			sed -i 's/CONFIG_DEBUG_KERNEL=.*/CONFIG_DEBUG_KERNEL=y/g' "$KERNELDIR"/arch/arm64/configs/sweet_defconfig
			BONUS_MSG="*Note*: KernelSU disabled version, enjoy your legacy rooting method (p.s. APatch is now supported!) 🤫"
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

	make $KERNEL_DEFCONFIG \
	CC=clang \
	LD=ld.lld \
	O=out 2>&1 | tee -a build.log

	make -j4 O=out LLVM=1 LLVM_IAS=1 \
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
	
	if ! [[ -f $KERNELDIR/out/arch/arm64/boot/Image.gz ]];then
	    tg_post_build "build.log" "Compile failed!!"
	    log warn "**** Compile Failed!!! ****"
	    exit 1
	fi
	log info "**** Kernel build completed ****"
	
	log info "**** Copying Image.gz, dtbo.img, dtb.img ****"
	cp -af $KERNELDIR/out/arch/arm64/boot/Image.gz $AK3DIR
	cp -af $KERNELDIR/out/arch/arm64/boot/dtbo.img $AK3DIR
	cp -af $KERNELDIR/out/arch/arm64/boot/dtb.img $AK3DIR
	
	log info "**** Time to zip up! ****"
	cd $AK3DIR
	zip -r9 ../$FINAL_ZIP.zip * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip
	cd $KERNELDIR
	
	# if ! [[ -f $FINAL_ZIP.zip ]]; then
	    # tg_post_build "$KERNELDIR/out/arch/arm64/boot/Image.gz-dtb" "Failed to zipping the kernel, Sending image file instead."
	    # exit 1
	# fi

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
