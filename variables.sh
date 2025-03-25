#!/bin/bash
KERNELNAME="Heliasts-cip"
DEVICENAME="Asus Zenfone Max Pro M1 (X00TD)"
ANDRVER="11-15"
ANDRVERTAG="(Red Velvet Cake - Vanilla Ice Cream)"
VARIANT="End Of Life"

AK3BRANCH=four19
KERBRANCH=cip
KERLINK="https://github.com/PurrrsLitterbox/x00td_kernel_4.19.git"

# Compiler
# 1 Neutron, 2 = TheRagingBeast
# 3 ElectroWizard, 4 RvClang
# 5 Google
COMP=5

# Build with KSU?
# 0 false, 1 true, b both KSU & Non KSU
WITHKSU=1

# Sign the build? make sure you have jdk! (0/1)
SIGN=1

# Push to Telegram? (0/1)
PUSHTG=1
# TG_CHAT_ID=
# TG_TOKEN=

# Target telegram is a supergroup?
TG_SUPER=1
# TG_TOPIC_ID=



# Additional Variables #####################
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

BUILDPROG="Initializing...."
ISIPESAN="🕒 <b>`date '+%d %b %Y, %H:%M %Z'`</b>
Masterpiece creation starts! 
For <b>$DEVICENAME</b>.
Crafted with <b>$(source /etc/os-release && echo "$NAME")</b>.
Full Log <a href='$CIRCLE_BUILD_URL'>click here!</a>.

Progress: "

IDPESAN=$(tg_post_msg "${ISIPESAN}${BUILDPROG}" | cut -d ":" -f 4 | cut -d "," -f 1)