#!/usr/bin/env bash

# Cloning Kernel Source
log info "Cloning Kernel Source"
git clone -qb "$KERBRANCH" --recursive --depth 15 "$KERLINK" kernel

# Verify Kernel Directory
if [[ -d kernel ]]; then
	log info "Cloning Kernel Source Done!"
	cd kernel && export KERNELDIR=$(pwd) KERVER=$(make kernelversion)

	# KSU Re-Sync
	rm -rf KernelSU-Next \
    && git clone -b next-susfs "https://github.com/KernelSU-Next/KernelSU-Next" KernelSU-Next
else
	log error "Cloning Kernel Source Failed! Exiting"
	exit 1
fi

ISIPESAN="🕒 <b>$BUILDDATE</b>
Masterpiece creation starts! 
📱 $DEVICENAME
🐧 Version $KERVER
🚢 $OSNAME
🖨 <a href='$CIRCLE_BUILD_URL'>Full logs</a>
Progress: "
tg_edit "${ISIPESAN}${BUILDPROG}"

# Specify Defconfig Paths
CONFIGPATHS="$KERNELDIR"/arch/arm64/configs/"$KERNEL_DEFCONFIG"

log info "Cloning Clang"
case "$COMP" in
	1)
		mkdir -p clang
		pushd clang
		# Download antman and sync clang
		curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" -o antman && bash antman -S=latest # 09092023 for clang 18
		# Create dummy elfedit so GNU binutils are picked from here
		cd bin
		if ! [[ -f aarch64-linux-gnu-elfedit ]]; then
			ln -s -p "aarch64-linux-gnu-ld" "aarch64-linux-gnu-elfedit"
		fi
		popd
		;;
	2)
		# mkdir -p "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
		wget -qO rvclang.tar.gz https://github.com/Rv-Project/RvClang/releases/download/20.1.0/RvClang-20.1.0-bolt-pgo-full_lto.tar.gz && tar -xzf rvclang.tar.gz && rm -f rvclang.tar.gz && mv RvClang clang
		;;
	3)
		mkdir -p "$KERNELDIR/clang"
		pushd "$KERNELDIR/clang"
		wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r522817.tar.gz -O "clang.tar.gz" && tar -xzf clang.tar.gz && rm -f clang.tar.gz
		popd
		;;
	4)
		mkdir -p "$KERNELDIR/clang"
		pushd "$KERNELDIR/clang"
		wget -q "$(curl -sL "https://raw.githubusercontent.com/PurrrsLitterbox/LLVM-stable/refs/heads/main/latestlink.txt")" -O "clang.tar.zst" && tar -xf clang.tar.zst && rm -f clang.tar.zst
		popd
		;;
	*)
		tg_post_msg "Clang unavailable! Aborting..."
		exit 1
		;;
esac
if [[ -f "$KERNELDIR/clang/bin/clang" ]]; then
	log info "Clang cloning done"
	export PATH="$KERNELDIR/clang/bin:$PATH"
else
	log error "Clang cloning failed! Aborting..."
	tg_post_msg "Clang cloning failed! Aborting compilation"
	exit 1
fi

export KBUILD_COMPILER_STRING=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

ISIPESAN="🕒 <b>$BUILDDATE</b>
Masterpiece creation starts! 
📱 $DEVICENAME
🐧 $KERVER
🛠 $KBUILD_COMPILER_STRING
🚢 $OSNAME
🖨 <a href='$CIRCLE_BUILD_URL'>Full logs</a>
Progress: "
tg_edit "${ISIPESAN}${BUILDPROG}"

log info "AnyKernel3 Time"
if ! git clone -qb "$AK3BRANCH" --depth=1 "$AK3LINK" AnyKernel3; then
	log error "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed! aborting compilation"
	exit 1
fi
AK3DIR=$KERNELDIR/AnyKernel3

log info "Generating Changelog"
echo "<b><#selectbg_g>$(date)</#></b>" > changelog
git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A) "</*>"}' >> changelog
echo "" >> changelog
echo "<b><#selectbg_g>Aroma Installer config by: @ItsRyuujiX</#></b>" >> changelog

pushd "$AK3DIR"
cp -af "$KERNELDIR"/changelog "$AK3DIR"/META-INF/com/google/android/aroma/changelog.txt
mv -f anykernel-real.sh anykernel.sh
sed -i "s/kernel.string=.*/kernel.string=$KERNELNAME/g" anykernel.sh
sed -i "s/kernel.type=.*/kernel.type=Stock-OverClock/g" anykernel.sh
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

pushd "$AK3DIR"/META-INF/com/google/android
mv -f update-binary update-binary-installer
mv -f aroma-binary update-binary
sed -i "s/KNAME/$KERNELNAME/g" aroma-config
sed -i "s/KVER/$KERVER/g" aroma-config
sed -i "s/KAUTHOR/$KBUILD_BUILD_USER/g" aroma-config
sed -i "s/KDEVICE/Zenfone Max Pro M1/g" aroma-config
sed -i "s/KBDATE/$DATE/g" aroma-config
sed -i "s/KVARIANT/$VARIANT/g" aroma-config
popd # "$AK3DIR"/META-INF/com/google/android
popd # "$AK3DIR"
log info "AnyKernel3 Done!"