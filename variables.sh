#!/bin/bash
KERNELNAME="Heliasts-cip"
DEVICENAME="Asus Zenfone Max Pro M1 (X00TD)"
ANDRVER="11-15"
ANDRVERTAG="(Red Velvet Cake - Vanilla Ice Cream)"
VARIANT="End Of Life"

KERBRANCH=cip
KERLINK="https://github.com/PurrrsLitterbox/x00td_kernel_4.19.git"
AK3BRANCH=four19
AK3LINK="https://github.com/sandatjepil/AnyKernel3"
KSUMGRLINK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v1.0.5/KernelSU_Next_v1.0.5_12430-release.apk"

# Compiler
# 1 Neutron, 2 RvClang
# 3 Google, 4 Kaleidoscope
COMP=4

# Build with KSU?
# 0 false, 1 true, b both KSU & Non KSU
WITHKSU=1

# Sign the build? make sure you have jdk! (0/1)
SIGN=1

# Send log after compiling? (0/1)
DEBUG=1

# Push to Telegram? (0/1)
PUSHTG=1
# TG_CHAT_ID=
# TG_TOKEN=

# Target telegram is a supergroup?
TG_SUPER=1
# TG_TOPIC_ID=

# Additional Variables #####################

# Specify Config Files
case $KERBRANCH in
	master) KERNEL_DEFCONFIG=vendor/X00TD_defconfig;;
	*) KERNEL_DEFCONFIG=asus/X00TD_defconfig;;
esac

DATE=$(date '+%d %m %Y') ZIPDATE=$(date '+%y%m%d-%H%M')
export KBUILD_BUILD_TIMESTAMP=$(date) ARCH=arm64 SUBARCH=arm64

# Log Function
blue='\033[0;34m' red='\033[0;31m' nocol='\033[0m'
log(){
	case $1 in
		info) echo -e "\n$blue$2$nocol\n";;
		error) echo -e "\n$red$2$nocol\n";;
	esac
}

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

tg_edit(){
if [[ $PUSHTG == 1 ]]; then
	curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/editMessageText" \
	-d "message_id=$IDPESAN" -d "parse_mode=html" -d "text=$1" \
	-d "chat_id=$TG_CHAT_ID" -d "disable_web_page_preview=true"
fi
}

BUILDDATE=$(date '+%d %b %Y, %H:%M %Z')
OSNAME=$(source /etc/os-release && echo "$NAME")
BUILDPROG="Initializing...."
ISIPESAN="🕒 <b>$BUILDDATE</b>
Masterpiece creation starts! 
For <b>$DEVICENAME</b>.
Crafted with <b>$OSNAME</b>.
Full Log <a href='$CIRCLE_BUILD_URL'>click here!</a>.

Progress: "
IDPESAN=$(tg_post_msg "${ISIPESAN}${BUILDPROG}" | cut -d ":" -f 4 | cut -d "," -f 1)