#!/bin/bash

# Cloning Kernel Source
log info "Cloning Kernel Source"
git clone -qb "$KERBRANCH" --recursive --depth 15 "$KERLINK" kernel

# Verify Kernel Directory
if [[ -d kernel ]]; then
	log info "Cloning Kernel Source Done!"
	cd kernel
	export KERNELDIR=$(pwd)
	KERVER=$(make kernelversion)
else
	log error "Cloning Kernel Source Failed! Exiting"
	exit 1
fi

ISIPESAN="🕒 <b>$BUILDDATE</b>
Masterpiece creation starts! 
For <b>$DEVICENAME</b>.
Kernel version <b>$KERVER</b>.
Crafted with <b>$OSNAME</b>.
Full log <a href='$CIRCLE_BUILD_URL'>click here!</a>

Progress: "
tg_edit "${ISIPESAN}${BUILDPROG}"

# Specify Defconfig Paths
case $(git rev-parse --abbrev-ref HEAD) in
	master) KERNEL_DEFCONFIG=vendor/X00TD_defconfig;;
	tom | cip | susfs) KERNEL_DEFCONFIG=asus/X00TD_defconfig;;
	*) KERNEL_DEFCONFIG=X00TD_defconfig;;
esac
CONFIGPATHS="$KERNELDIR"/arch/arm64/configs/"$KERNEL_DEFCONFIG"

log info "Cloning Clang"
case $COMP in
	1)
		mkdir -p clang && cd clang
		# Download antman and sync clang
		curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" -o antman && bash antman -S=latest # 09092023 for clang 18
		# Create dummy elfedit so GNU binutils are picked from here
		cd bin
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
	5)
		mkdir -p "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
		wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r522817.tar.gz -O "clang.tar.gz" && tar -xzf clang.tar.gz && rm -f clang.tar.gz
		cd $KERNELDIR
		export PATH="$KERNELDIR/clang/bin:$PATH"
		[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
		;;
	6)
		mkdir -p "$KERNELDIR/clang" && cd "$KERNELDIR/clang"
		wget -q https://github.com/PurrrsLitterbox/clang-releases/releases/download/20250327-0946-Asia/clang.tar.zst -O "clang.tar.zst" && tar -xf clang.tar.zst && rm -f clang.tar.zst
		cd $KERNELDIR
		export PATH="$KERNELDIR/clang/bin:$PATH"
		[[ -f "$KERNELDIR/clang/bin/clang" ]] || exit 1
		;;
	*)
		tg_post_msg "Clang unavailable! Aborting..."
		exit 1
		;;
esac
export KBUILD_COMPILER_STRING=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

ISIPESAN="🕒 <b>$BUILDDATE</b>
Masterpiece creation starts! 
For <b>$DEVICENAME</b>.
Kernel version <b>$KERVER</b>.
Using <b>$KBUILD_COMPILER_STRING</b>
Crafted with <b>$OSNAME</b>.
Full log <a href='$CIRCLE_BUILD_URL'>click here!</a>

Progress: "
tg_edit "${ISIPESAN}${BUILDPROG}"

log info "AnyKernel3 Time"
AK3DIR=$KERNELDIR/AnyKernel3
if ! git clone -qb "$AK3BRANCH" --depth=1 https://github.com/sandatjepil/AnyKernel3 AnyKernel3; then
	log error "Cloning failed! Aborting..."
	tg_post_msg "Cloning AnyKernel3 Failed, aborting compilation"
	exit 1
fi

log info "****Generating Changelog****"
echo "<b><#selectbg_g>$(date)</#></b>" > changelog
git log --oneline -n15 | cut -d " " -f 2- | awk '{print "<*> " $(A) "</*>"}' >> changelog
echo "" >> changelog
echo "<b><#selectbg_g>Aroma Installer config by: @ItsRyuujiX</#></b>" >> changelog

cd "$AK3DIR"
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
log info "AnyKernel3 Done!"