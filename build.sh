#!/bin/bash
export TZ="Asia/Jakarta"

if [ -f kernel/arch/arm64/configs/X00TD_defconfig ]; then
    cd kernel
    KERNELDIR=$(pwd)
else
    echo "Kernel Cloning Failed! aborting..."
    exit 1
fi

# Additional command (if you're lazy to commit :v)
sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-Heliasts-Ἡλιαστής🏛"/g' arch/arm64/configs/X00TD_defconfig

#set -e
# Set the Variables
KERNELNAME="Heliasts"
DEVICENAME="Asus Zenfone Max Pro M1 (X00TD)"
ANDROIDVER="9-13"
KERVER=$(make kernelversion)
VARIANT="End Of Life"

# set compiler
# 1 = Neutron Clang
# 2 = TheRagingBeast Clang
# 3 = ElectroWizard Clang
# 4 = Proton Clang
# 5 = Snapdragon Clang x GCC
COMP=1

# You want to sign your build?
# 1 = yes || 0 = no
SIGN=1

# Define is the target telegram is a supergroup or not
# 1 = true || 0 = false
TG_SUPER=1

# Additional Variables
KERNEL_DEFCONFIG=X00TD_defconfig
DATE=$(date '+%d %m %Y')
export KBUILD_BUILD_TIMESTAMP=$(date)
export KBUILD_BUILD_USER="Purrr"
export KBUILD_BUILD_HOST="WizardPrjkt"
export ARCH=arm64
export SUBARCH=arm64

############################################################
tg_post_msg(){
if [[ $TG_SUPER == 1 ]]; then
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
    -d "message_thread_id=$TG_TOPIC_ID" -d "parse_mode=html" -d "text=$1" \
    -d "chat_id=$TG_CHAT_ID" -d "disable_web_page_preview=true"
else
	curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
	-d "chat_id=$TG_CHAT_ID" -d "disable_web_page_preview=true" \
	-d "parse_mode=html" -d "text=$1"
fi
}
tg_post_build() {
if [[ $TG_SUPER == 1 ]]; then
	curl -s "https://api.telegram.org/bot$TG_TOKEN/sendDocument" -F "document=@$1" \
	-F "chat_id=$TG_CHAT_ID" -F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" -F "caption=$2" -F "message_thread_id=$TG_TOPIC_ID"
else
	curl -s "https://api.telegram.org/bot$TG_TOKEN/sendDocument" -F "document=@$1" \
	-F "chat_id=$TG_CHAT_ID" -F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" -F "caption=$2"
fi
}
############################################################

tg_post_msg "🕒 <b>`date '+%d %b %Y, %H:%M %Z'`</b>
Masterpiece creation starts! 
Version <b>$KERVER</b> for <b>$DEVICENAME</b>.
Crafted with <b>$(source /etc/os-release && echo "$NAME" | cut -d" " -f1)</b>.
🔍 Compilation progress <a href='$CIRCLE_BUILD_URL'>click here!</a>."

echo "Cloning Clang"
if [[ $COMP == "1" ]]; then
	# apt-get install -y libarchive-tools
	mkdir -p clang && cd clang
	curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" -o antman
	bash antman -S=09092023
	# bash antman --patch=glibc
	cd $KERNELDIR
	export PATH="$KERNELDIR/clang/bin:$PATH"
	[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
elif [[ $COMP == "2" ]]; then
	git clone https://gitlab.com/varunhardgamer/trb_clang --depth=1 -b 17 --single-branch clang || exit 1
	export PATH="$KERNELDIR/clang/bin:$PATH"
elif [[ $COMP == "3" ]]; then
	# git clone https://gitlab.com/Tiktodz/electrowizard-clang.git --depth=1 -b 16 --single-branch clang || exit 1
	mkdir "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
	wget -O ew.tar.gz https://github.com/Tiktodz/electrowizard-clang/releases/download/ElectroWizard-Clang-18.1.8-release/ElectroWizard-Clang-18.1.8.tar.gz && tar -xzf ew.tar.gz && rm -f ew.tar.gz && cd $KERNELDIR
	export PATH="$KERNELDIR/clang/bin:$PATH"
	[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
elif [[ $COMP == "4" ]]; then
	git clone https://gitlab.com/LeCmnGend/clang --depth=1 -b clang-13 --single-branch clang || exit 1
	export PATH="$KERNELDIR/clang/bin:$PATH"
elif [[ $COMP == "5" ]]; then
	apt-get install wget libncurses5 -y
	wget -O sdc.tar.gz https://github.com/sandatjepil/SDClang/releases/download/v14.1.5/sdclangxgcc.tar.gz && tar -xzf sdc.tar.gz && rm -f sdc.tar.gz
	export PATH="$KERNELDIR/sdclang/bin:$KERNELDIR/gcc64/bin:$KERNELDIR/gcc32/bin:$PATH"
	export LD_LIBRARY_PATH="$KERNELDIR/sdclang/lib:$LD_LIBRARY_PATH"
	[[ -f "$KERNELDIR/sdclang/bin/clang" ]] || exit 1
else
	echo "Clang unavailable! Aborting..."
	exit 1
fi
if [[ "$COMP" == "5" ]]
	export KBUILD_COMPILER_STRING="Snapdragon™ clang version 14.1.5"
else
	export KBUILD_COMPILER_STRING=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
fi

# Generating Changelog
echo "<b><#selectbg_g>$(date)</#></b>" > changelog
git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A) "</*>"}' >> changelog
echo "" >> changelog
echo "<b><#selectbg_g>Aroma Installer config by: @ItsRyuujiX</#></b>" >> changelog

echo "**** AnyKernel3 Time ****"
AK3DIR=$KERNELDIR/AnyKernel3
echo "Cloning AnyKernel3"
if ! git clone --depth=1 -b zeus https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	echo "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	exit 1
fi

cd "$AK3DIR"
cp -af "$KERNELDIR"/changelog "$AK3DIR"/META-INF/com/google/android/aroma/changelog.txt
mv anykernel-real.sh anykernel.sh
sed -i "s/kernel.string=.*/kernel.string=$KERNELNAME/g" anykernel.sh
sed -i "s/kernel.type=.*/kernel.type=Stock/g" anykernel.sh
sed -i "s/kernel.for=.*/kernel.for=$DEVICENAME/g" anykernel.sh
sed -i "s/kernel.compiler=.*/kernel.compiler=$KBUILD_COMPILER_STRING/g" anykernel.sh
sed -i "s/kernel.made=.*/kernel.made=$KBUILD_BUILD_USER/g" anykernel.sh
sed -i "s/kernel.version=.*/kernel.version=$KERVER/g" anykernel.sh
sed -i "s/message.word=.*/message.word=Kernel need some time to settle./g" anykernel.sh
sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
sed -i "s/build.type=.*/build.type=$VARIANT/g" anykernel.sh
sed -i "s/supported.versions=.*/supported.versions=$ANDROIDVER/g" anykernel.sh
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
echo "***** AnyKernel3 Done! *****"

# Speed up build process
MAKE="./makeparallel"

# Now building process is a function
start_cooking() {
	FINAL_ZIP="$KERNELNAME-$1-$KERVER-$(date '+%y%m%d%H%M')"
	
	# Clean Up Output Directory
	if ! [[ -d "$KERNELDIR"/out ]]; then
		mkdir -p "$KERNELDIR"/out
		make O=out clean
	else
		rm -rf " $KERNELDIR"/out
		mkdir -p "$KERNELDIR"/out
		make O=out clean
	fi
	
	BUILD_START=$(date +"%s")
	blue='\033[0;34m'
	cyan='\033[0;36m'
	yellow='\033[0;33m'
	red='\033[0;31m'
	nocol='\033[0m'

	echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
	echo -e "$blue***********************************************"
	echo "          BUILDING KERNEL          "
	echo -e "***********************************************$nocol"
	make $KERNEL_DEFCONFIG O=out 2>&1 | tee -a error.log

	if [[ $COMP == 4 ]]; then
		make -j$(nproc --all) O=out LLVM=1 \
	    CC="$KERNELDIR/clang/bin/clang" \
	    CROSS_COMPILE="$KERNELDIR/clang/bin/aarch64-linux-gnu-" \
	    CROSS_COMPILE_ARM32="$KERNELDIR/clang/bin/arm-linux-gnueabi-" \
	    CLANG_TRIPLE="aarch64-linux-gnu-" \
	    AR="$KERNELDIR/clang/bin/llvm-ar" \
	    LD="$KERNELDIR/clang/bin/ld.lld" \
	    NM="$KERNELDIR/clang/bin/llvm-nm" \
	    OBJCOPY="$KERNELDIR/clang/bin/llvm-objcopy" \
	    OBJDUMP="$KERNELDIR/clang/bin/llvm-objdump" \
	    STRIP="$KERNELDIR/clang/bin/llvm-strip" 2>&1 | tee -a error.log
	elif [[ $COMP == 5 ]]; then
	    export LD=ld.lld
	    export HOSTLD=ld.lld
	    ClangMoreStrings="AR=llvm-ar NM=llvm-nm AS=llvm-as STRIP=llvm-strip HOST_PREFIX=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf HOSTAR=llvm-ar HOSTAS=llvm-as"
	    make -j$(nproc --all) O=out LLVM=1 \
	        CC=clang \
	        HOSTCXX=clang++ \
	        HOSTCC=clang \
	        CLANG_TRIPLE=aarch64-linux-gnu- \
	        CROSS_COMPILE=aarch64-linux-android- \
	        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
	        CROSS_COMPILE_COMPAT=aarch64-linux-gnu- ${ClangMoreStrings} 2>&1 | tee -a error.log
	else
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
	fi

	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	
	echo "**** Kernel Compilation Completed ****"
	echo "**** Verify Image.gz-dtb ****"
	
	if ! [[ -f $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb ]];then
	    tg_post_build "error.log" "Compile Error!!"
	    echo "$red Compile Failed!!!$nocol"
	    exit 1
	fi

	echo "**** Copying Image.gz-dtb ****"
	cp -af $KERNELDIR/out/arch/arm64/boot/Image.gz-dtb $AK3DIR
	
	echo "**** Time to zip up! ****"
	cd $AK3DIR
	zip -r9 ../$FINAL_ZIP.zip * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip
	cd $KERNELDIR
	
	if ! [[ -f $FINAL_ZIP.zip ]]; then
	    tg_post_build "$KERNELDIR/out/arch/arm64/boot/Image.gz-dtb" "Failed to zipping the kernel, Sending image file instead."
	    exit 1
	fi

	if [[ $SIGN == 1 ]]; then
		mv $FINAL_ZIP* krenul.zip
		if ! [[ -f zipsigner-3.0.jar ]]; then
			curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
		fi
		java -jar zipsigner-3.0.jar krenul.zip krenul-signed.zip
		FINAL_ZIP+="-signed"
		mv krenul-signed.zip $FINAL_ZIP.zip
	fi
	
	MD5CHECK=$(md5sum "$FINAL_ZIP.zip" | cut -d' ' -f1)

	echo "**** Uploading your zip now ****"
	tg_post_build "$FINAL_ZIP.zip" "⏳ *Compile Time*
 $(($DIFF / 60)) minute(s) $(($DIFF % 60)) seconds
📱 *Device*
${DEVICENAME}
🐧 *Kernel Version*
${KERVER}
🔥 *Supported Android Version*
${ANDROIDVER}
🛠 *Compiler*
${KBUILD_COMPILER_STRING}
💾 *MD5 Checksum*
\`${MD5CHECK}\`
🆕 *Last Changelog*
\``git log --oneline -n1 | cut -d" " -f2-`\`

⚠️ ${BONUS_MSG}"

	# Removing zip files for second compilation
	rm -rf *.zip
}

# Function Trigger Here
# With KSU
BONUS_MSG="*Note:* KernelSU switched to KernelSU-Next version 1.0.4 🤫
https://github.com/rifsxd/KernelSU-Next"
start_cooking "KSU"

# Without KSU
sed -i 's/CONFIG_KSU=.*/CONFIG_KSU=n/g' "$KERNELDIR"/arch/arm64/configs/X00TD_defconfig
BONUS_MSG="*Note*: KernelSU disabled version, enjoy your legacy rooting method (p.s. APatch is now supported!) 🤫"
start_cooking "NoKSU"