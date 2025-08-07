#!/bin/bash

# no multiarch. create only archs available so users cant install on archs not yet released.

_tmp=/tmp/packages_$(date +%s%N)
_g_url=$(curl -s -X RAW http://keyserver/gitea-url)
_g_user=$(curl -s -X RAW http://keyserver/gitea-user)
_g_pass=$(curl -s -X RAW http://keyserver/gitea-pass)
mkdir -p "$_tmp"
cd "$_tmp"
git clone https://$_g_url/$_g_user/telerising-helper
if [ ! -d telerising-helper ]; then exit 1; fi
cd telerising-helper/packages/appimage

_cur=""

_msg=""


while read -r _line
do
	if [[ "$_line" =~ ^telerising-v([0-9.]+)_(.*)\.zip ]]
	then
		_ver=${BASH_REMATCH[1]}
		_arch=${BASH_REMATCH[2]}
	else
		continue
	fi
	case $_arch in
		x86-64_linux|arm64_raspbian|armhf_raspbian)
			if [ -e "$_ver/telerising-$_ver-${_arch//-/_}.failed" ]; then continue; fi
			if [ -e "$_ver/telerising-$_ver-${_arch//-/_}.AppImage" ]; then continue; fi
			mkdir -p "$_ver"
			cp $_arch.AppImage  "$_ver/telerising-$_ver-${_arch//-/_}.AppImage"
			git add "$_ver/telerising-$_ver-${_arch//-/_}.AppImage"
			git commit -a -m "$_ver/telerising-$_ver-${_arch//-/_}.AppImage"
		;;
	esac
done < <(curl -s https://api.github.com/repos/sunsettrack4/telerising-api/releases |jq -r '.[]|.assets|.[]|.name')



git push https://$_g_user:$_g_pass@$_g_url/$_g_user/telerising-helper
rm -r "$_tmp"
