#!/bin/bash
# todo:
#  - freebsd: check if fbsd has v6 v7 v8 and add libs
#  - test busybox working
#  - use proot on termux when installed

export PYTHONUNBUFFERED=1
_mirror=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main
_sub=
_user=telerising-script
_install_path=${1:-~/telerising}
_system=$(echo $2)
_os=$(uname -o)
_kernel=$(uname -s)
_machine=$(uname -m)
_termux_busybox=1.37.0
# colors
_c_red='\033[0;31m'
_c_clear='\033[0m'
_c_blink='\033[5m'

_os=${_os,,}
_kernel=${_kernel,,}
_machine=${_machine,,}

_api=api

if [ "${TR_VERSION:0:1}" == "v" ]
then
	TR_VERSION=${TR_VERSION:1}
fi

if [ "$1" == "-d" ] || [ "$1" == "--devices" ]
then
	echo "####################################################################################################"
	echo "#                                                                                                  #"
	echo "#                                     tested devices                                               #"
	echo "#                                                                                                  #"
	echo "#      * Windows 10 / 11                                                                           #"
	echo "#        - wls1         | debian, ubuntu, no proot                                                 #"
	echo "#        - wls2         | debian, ubuntu                                                           #"
	echo "#        - cygwin       | 64bit                                                                    #"
	echo "#                                                                                                  #"
	echo "#      * Android                                                                                   #"
	echo "#        - termux       | armv7l, armv8l, aarch64 | using proot                                    #"
	echo "#                                                                                                  #"
	echo "#      * Linux                                                                                     #"
	echo "#        - newenigma    | aarch64 | DM AIO Image / Gemini 4.2 Plugin / One/Two                     #"
	echo "#        - terramaster  | x86_64 | TOS6                                                            #"
	echo "#        - freebsd      | x86_64 | needs ABI | script will ask to enable it                        #"
	echo "#        - opensuse     | x86_64 | leap, tumbleweed                                                #"
	echo "#        - debian       | armv7l, armv8l, aarch64, x86_64                                          #"
	echo "#        - ubuntu       | armv7l, armv8l, aarch64, x86_64                                          #"
	echo "#        - RPI          | armv6l, armv7l, armv8l, aarch64, x86_64                                  #"
	echo "#        - alpine       | armv6l, armv7l, armv8l, aarch64, x86_64                                  #"
	echo "#        - fedora       | aarch64, x86_64                                                          #"
	echo "#        - rocky        | aarch64, x86_64                                                          #"
	echo "#        - oracle       | aarch64, x86_64                                                          #"
	echo "#        - redhat/ubi8  | aarch64, x86_64                                                          #"
	echo "#                                                                                                  #"
	echo "####################################################################################################"
	exit 0
fi

if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo "################################################################################################"
	echo "#                                                                                              #"
	echo "# usage: [install_dir] [system]                                                                #"
	echo "#                                                                                              #"
	echo "# this script needs root for then following tasks: (obsolete, using proot and busybox now)     #"
	echo "#    - install tzdata       | if not exists in /usr/share/zonedata                             #"
	echo "#    - modifying /etc/hosts | telerising needs to resolve our own hostname                     #"
	echo "#    - add user             | if possible create user telerising else run under root           #"
	echo "#    - package system       | if available try to install needed packages                      #"
	echo "#                                                                                              #"
	echo "#                                                                                              #"
	echo "# system tools needed:                                                                         #"
	echo "#    - wget or curl                                                                            #"
	echo "#    - tar                                                                                     #"
	echo "#    - unzip                                                                                   #"
	echo "#    - bash                                                                                    #"
	echo "#                                                                                              #"
	echo "# params:                                                                                      #"
	echo "#    - install_dir | where should telerising be installed | default [~/telerising]             #"
	echo "#    - systems:                                                                                #"
	echo "#      - empty          | try to autodetect                                                    #"
	echo "#      - arm64_raspbian | arm64 devices                                                        #"
	echo "#      - x86-64_linux   | amd64 devices                                                        #"
	echo "#      - armhf_raspbian | armhf devices                                                        #"
	echo "#      - x86-64_windows | windows 64bit                                                        #"
	echo "#                                                                                              #"
	echo "# other:                                                                                       #"
	echo "#    - install modified providers.json for waipu support                                       #"
	echo "#    - put you own modified providers.json into [install_dir] to use it instead                #"
	echo "#                                                                                              #"
	echo "# examples:                                                                                    #"
	echo "#                                                                                              #"
	echo "# export helper_url=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main #"
	echo "# curl -s \$helper_url/api.sh|bash -s -- /opt/telerising arm64_raspbian                         #"
	echo "# curl -s \$helper_url/api.sh|bash -s -- /opt/telerising x86-64_linux                           #"
	echo "# curl -s \$helper_url/api.sh|bash -s -- /opt/telerising armhf_raspbian                         #"
	echo "#                                                                                              #"
	echo "# wget -qO - \$helper_url/api.sh|bash -s -- /opt/telerising arm64_raspbian                      #"
	echo "# wget -qO - \$helper_url/api.sh|bash -s -- /opt/telerising x86-64_linux                        #"
	echo "# wget -qO - \$helper_url/api.sh|bash -s -- /opt/telerising armhf_raspbian                      #"
	echo "#                                                                                              #"
	echo "# quick install to home dir to test new version:                                               #"
	echo "# [curl|wget] \$helper_url/api.sh|bash -s                                                       #"
	echo "#                                                                                              #"
	echo "# docker | multiarch one url                                                                   #"
	echo "#                                                                                              #"
	echo "# docker run -d --net host -v ~/telerising:/telerising ad0lar/telerising-alpine                #"
	echo "#                                                                                              #"
	echo "# support on kodinerds https://www.kodinerds.net/wcf/user/32559-fds97avvs/                     #"
	echo "#                                                                                              #"
	echo "################################################################################################"
	exit 0
fi

function dloader {
	local _bin
	if hash wget &>/dev/null; then _bin=wget; else if hash curl &>/dev/null; then _bin=curl; fi; fi
	#if [ -e ./bin/wget ]; then _bin=./bin/wget; fi
	if [ "$_bin" == "" ]; then >&2 echo no downloader on your system, need curl or wget; exit 1; fi
	echo "$_bin"
}

function dl {
	local _bin _sub _url
	_bin=$(dloader)
	_sub=$2
	>&2 echo "$_bin: downloading $_sub $1"
	if [ "${1:0:4}" == "http" ]
	then
		_url=$1
	else
		_url="$_mirror/$_sub/$1"
	fi
	if [[ "$_bin" == *"wget"* ]]
	then
		wget "$_url" &>/dev/null
		if [ $? -ne 0 ]; then >&2 echo "failed downloading $1"; rm -f "$1"; exit 1; fi
	else
		curl -LO "$_url" &>/dev/null
		if [ $? -ne 0 ]; then >&2 echo "failed downloading $1"; rm -f "$1"; exit 1; fi
	fi
}

function update {
	local _latest _ver _file _api_search _api_path _del _bin
	_bin=$(dloader)
	if [ "$TR_VERSION" == "" ]
	then
		if [ "$_bin" == "curl" ]
		then
			_latest=$($_bin -s https://api.github.com/repos/sunsettrack4/telerising-api/releases/latest 2>/dev/null)
		else
			_latest=$($_bin -qO - https://api.github.com/repos/sunsettrack4/telerising-api/releases/latest 2>/dev/null)
		fi
		if [[ ! "$_latest" =~ /releases/download/v([.0-9]+)/telerising-v[.0-9]+_$_system\.zip ]]
		then
			if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
			>&2 echo update check failed
			return
		fi
	else
		if [ "$_bin" == "curl" ]
		then
			_latest=$($_bin -s https://api.github.com/repos/sunsettrack4/telerising-api/releases 2>/dev/null)
		else
			_latest=$($_bin -qO - https://api.github.com/repos/sunsettrack4/telerising-api/releases 2>/dev/null)
		fi
		if [[ ! "$_latest" =~ /releases/download/v($TR_VERSION)/telerising-v${TR_VERSION}_$_system\.zip ]]
		then
			if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
			>&2 echo update check failed
			return
		fi
	fi

	_ver=${BASH_REMATCH[1]}
	_file=telerising-v${_ver}_$_system.zip
	if [ "$(cat installed.ver 2>/dev/null)" == "$_ver" ]
	then
		>&2 echo update not needed v$_ver
		return
	fi
	if [ ! -e "$_file" ]
	then
		dl https://github.com/sunsettrack4/telerising-api/releases/download/v$_ver/$_file
	fi
	rm -rf tmp
	mkdir -p tmp
	>&2 echo extracting..
	if [ -e bin/unzip ]; then _unzip=bin/unzip; else _unzip=unzip; fi
	$_unzip -o $_file -d tmp &>/dev/null
	if [ $? -ne 0 ]
	then
		>&2 echo error extract.
		rm -f $_file
		if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
		return
	fi
	_api_search=$(./bin/find tmp -name $_api)
	if [ "$_api_search" == "" ]
	then
		>&2 echo missing api after extract
		rm -fr tmp
		if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
		return
	fi
	_api_path=$(dirname "$_api_search")
	if [ "$_api_path" == "" ]
	then
		>&2 echo missing api path after extract
		rm -rf tmp
		if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
	fi
	mv "$_api_path/app/static/json/providers.json" providers.json.contrib
	# cleanup old telerising
	while read -r _del
	do
		if [[ "${_del,,}" == *"providers."* ]]; then continue; fi
		if [ "${_del,,}" == "cookie_files" ]; then continue; fi
		if [ "${_del,,}" == "settings.json" ]; then continue; fi
		if [ "${_del,,}" == "tmp" ]; then continue; fi
		if [ "${_del,,}" == "bin" ]; then continue; fi
		if [ "${_del,,}" == "tzdata.zi" ]; then continue; fi
		if [ "${_del,,}" == "zone1970.tab" ]; then continue; fi
		if [ "${_del,,}" == "run.sh" ]; then continue; fi
		rm -fr $_del
	done < <(ls)
	cp -r "$_api_path/"* .
	rm -rf tmp
	echo $_ver > installed.ver
}

echo "###########################################################################"
echo "#                     telerising universal installer                      #"
echo "#                                  v0.1                                   #"
echo "#                                                                         #"
echo "#            support on https://www.kodinerds.net/wcf/user/32559          #"
echo "#         support telerising https://www.kodinerds.net/thread/72127       #"
echo "#                                                                         #"
echo "#                       want to spend some drinks?                        #"
echo "#                       https://paypal.me/betaface                        #"
echo "#                                                                         #"
echo "#           want to spend some haribos to the telerising author?          #"
echo "#                     https://paypal.me/sunsettrack4                      #"
echo "#                                                                         #"
echo "###########################################################################"
echo

# register ctrl + c
trap end SIGINT
_trap=0

function end {
	# cygwin needs to kill the task
	if [ $_trap -eq 0 ]; then >&2 echo killing processes; fi
	if [ "$_os" == "cygwin" ] && [ $_trap -eq 0 ]
	then
		taskkill /f /im $_api
	fi
	for _kill in $(ls ld-* 2>/dev/null)
	do
		# try all ways without check if any app exists
		./bin/kill $(./bin/pgrep -f $_kill 2>/dev/null) &>/dev/null
	done
	./bin/deluser telerising-script &>/dev/null
	./bin/delgroup telerising-script &>/dev/null
	rm -r proot-tmp &>/dev/null
	_trap=1
	exit 1
}

if [[ -t 1 ]]
then
	_auto=0
else
	_auto=1
fi

if [[ "~" == *"/com.termux/"* ]]
then
	_os=termux
fi

# perms check

#if [ "$_os" == "cygwin" ]
#then
#	# cygwin no root needed
#	>&2 echo running under cygwin
#elif [ "$_os" == "termux" ]
#then
#	# termux no root
#	>&2 echo running under termux
#elif [ $(id -u) -ne 0 ]
#then
#	echo we need root sorry.
#	exit 1
#fi

if [ "${_kernel,,}" == "freebsd" ]
then
	if [[ ! "$(sysrc linux_enable)" == *": YES"* ]]
	then
		if [ $_auto -eq 1 ]
		then
			>&2 echo -n "please enable linux ABI before running unattended"
			exit 1
		fi
		>&2 echo -n "on FreeBSD we need ABI, enable it now? N/y: "
		read -u2 -n1 _install
		if [ "${_install,,}" == "y" ]
		then
			echo enabled
			sysrc linux_enable="YES"
			service linux start
		else
			echo we need it sorry, script stopped.
			exit 1
		fi
	fi
fi

# cd into install folder

# some test to make sure we not destroy users system with wrong paths

if [ "$_install_path" == "/" ]; then >&2 echo choose other folder to install not root; exit 1; fi
if [[ "$_install_path" == *"/tmp/"* ]]; then >&2 echo; echo; echo warning if you install into tmp you telerising settings may be deleted on next reboot; echo; echo; echo; sleep 5; fi
if [[ "$_install_path" == *"/root/"* ]]; then >&2 echo; echo; echo -e "${_c_red}${_c_blink}warning${_c_clear}${_c_red} if you install into ${_c_clear}'/root'${_c_red} i cannot use ${_c_clear}'su'${_c_red}. continue in 10s.${_c_clear}"; echo; echo; echo;sleep 10; fi

mkdir -p "$_install_path"
if [ $? -ne 0 ]; then echo error creating telerising folder.; exit 1; fi
if [ ! -d "$_install_path" ]; then echo error creating telerising folder.; exit 1; fi
cd "$_install_path"

if [ "$_system" == "" ]
then
	echo -n "detecting system: "
	case $(uname -m) in
		x86_64|amd64)
			if [ "$_os" == "cygwin" ]
			then
				>&2 echo using windows build on cygwin $(uname -m)
				_system=x86-64_windows
			else
				>&2 echo using linux $(uname -m)
				_system=x86-64_linux
			fi
		;;
		# v8l is 32bit in 64bit
		armv6l|armv7l|armv8l)
			echo using armhf_raspbian $(uname -m)
			_system=armhf_raspbian
		;;
		aarch64)
			echo using arm64_raspbian $(uname -m)
			_system=arm64_raspbian
		;;
		*)
			echo unknown $(uname -m)
			exit 1
		;;
	esac
fi

echo
# cygwin use windows build
if [ "$_os" == "cygwin" ]
then
	if [ ! "$_machine" == "x86_64" ]
	then
		>&2 echo cygwin is only supported on x86_64
		exit 1
	fi
	_system=x86-64_windows
	_api=api.exe
fi

echo
# dl busybox and proot
case $_os in
	cygwin)
		# ignore
		if [ ! -e bin/$_system-busybox ]; then dl $_system-busybox busybox; fi
		if [ ! -e bin/$_system-busybox ]; then mv $_system-busybox bin; fi
	;;
	*)
		mkdir -p bin
		if [ "$_os" == "termux" ]
		then
			export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:bin
			if [ ! -e bin/$_system-proot ]; then dl $_system-proot-termux proot proot; mv $_system-proot-termux bin/$_system-proot; fi
			if [ ! -e bin/$_system-busybox ]; then dl $_system-busybox-termux busybox; mv $_system-busybox-termux bin/$_system-busybox; fi
			if [ ! -e bin/libbusybox.so.$_termux_busybox ]; then dl $_system-busybox-termux-libbusybox.so.$_termux_busybox busybox; mv $_system-busybox-termux-libbusybox.so.$_termux_busybox bin/libbusybox.so.$_termux_busybox; fi
		else
			if [ ! -e bin/$_system-proot ]; then dl $_system-proot proot; fi
			if [ ! -e bin/$_system-busybox ]; then dl $_system-busybox busybox; fi
			if [ ! -e bin/$_system-busybox ]; then mv $_system-busybox bin; fi
			if [ ! -e bin/$_system-proot ]; then mv $_system-proot bin; fi
		fi
	;;
esac

chmod +x bin/$_system-busybox &>/dev/null
chmod +x bin/$_system-proot &>/dev/null

_busybox=$(ls /bin/busybox /usr/bin/busybox 2>/dev/null|head -n1)

if [ "$_busybox" == "" ]
then
	if [ -e bin/$_system-busybox ]
	then
		_busybox=bin/$_system-busybox
	fi
fi


if [ ! -e bin/wget ]; then ln -s $_busybox bin/wget; fi
if [ ! -e bin/find ]; then ln -s $_busybox bin/find; fi
if [ ! -e bin/hostname ]; then ln -s $_busybox bin/hostname; fi
if [ ! -e bin/unzip ]; then ln -s $_busybox bin/unzip; fi
if [ ! -e bin/kill ]; then ln -s $_busybox bin/kill; fi
if [ ! -e bin/pgrep ]; then ln -s $_busybox bin/pgrep; fi
if [ ! -e bin/su ]; then ln -s $_busybox bin/su; fi
if [ ! -e bin/addgroup ]; then ln -s $_busybox bin/addgroup; fi
if [ ! -e bin/delgroup ]; then ln -s $_busybox bin/delgroup; fi
if [ ! -e bin/adduser ]; then ln -s $_busybox bin/adduser; fi
if [ ! -e bin/deluser ]; then ln -s $_busybox bin/deluser; fi
if [ ! -e bin/id ]; then ln -s $_busybox bin/id; fi
if [ ! -e bin/chown ]; then ln -s $_busybox bin/chown; fi

# package systems removed busybox

# is there anybody out there?
if [ ! -f $_api ]
then
	echo
	echo -n "missing telerising. install it? auto install in 5s (Y/n): "
	if [ $_auto -eq 1 ]
	then
		_install=y
	else
		read -n1 -t5 _install </dev/tty
	fi
	if [ "${_install,,}" == "n" ];then echo; echo "cancelled"; exit 0; fi
	echo
	update
else
	echo
	if [ ! "$TR_VERSION" == "" ]
	then
		# force down/upgrade when TR_VERSION is set
		_install=y
	elif [ $_auto -eq 1 ]
	then
		_install=y
	else
		echo -n "update telersing?. auto skipping in 5s. (y/N): "
		read -n1 -t5 _install </dev/tty
	fi
	echo
    if [ "${_install,,}" == "y" ]
	then
		update
	else
		echo skipping update
	fi
fi

echo
if [ "$TR_PROVIDERS" == "" ]
then
	if [ $_auto -eq 1 ]
	then
		# docker auto
		if [ ! -e providers.json ]
		then
			# nothing there. using our patched ver.
			_install=y
		else
			# user may have his own file put in
			_install=n
		fi
	else
		echo -n "install modified providers.json for waipu support? skipping in 5s. (y/N): "
		read -n1 -t5 _install </dev/tty
	fi
	if [ "${_install,,}" == "y" ]
	then
		echo installing
		rm -f providers.json
		dl providers.json
		cp providers.json app/static/json/providers.json
	else
		if [ -e providers.json ]
		then
			echo found previous downloaded provider.json.
			cp providers.json app/static/json/providers.json
		else
			echo "skipped"
		fi
	fi
else
	>&2 echo using "$TR_PROVIDERS"
	cp "$TR_PROVIDERS" app/static/json/providers.json
fi

if [ ! "$TR_SETTINGS" == "" ]
then
	if [ -f settings.json ]
	then
		cp settings.json settings.json.$(date +%s%N)
	fi
	rm -f settings.json
	ln -s "$TR_SETTINGS" settings.json
fi

if [ ! "$TR_COOKIES" == "" ]
then
	if [ -d cookie_files ] && [ ! -L cookie_files ]
	then
		mv cookie_files cookie_files.$(date +%s%N)
	fi
	rm -f cookie_files
	ln -s "$TR_COOKIES" cookie_files
fi

# hostname check
echo
if [ -e /etc/hosts ]
then
	>&2 echo "setting hostname"
	cat /etc/hosts > hosts
	echo 127.0.0.1 $(./bin/hostname) >> hosts &>/dev/null
fi

if [ -e /etc/resolv.conf ]
then
        >&2 echo "setting resolv.conf"
        cat /etc/resolv.conf > resolv.conf
fi

# zone data
echo
if [ ! -e tzdata.zi ]; then dl tzdata.zi; fi
if [ ! -e zone1970.tab ]; then dl zone1970.tab; fi

# dl libs
echo
case $_system in
	arm64_raspbian)
		if [ ! -e ld-linux-aarch64.so.1 ]; then dl ld-linux-aarch64.so.1 "$_system"; fi
		if [ ! -e libc.so.6 ]; then dl libc.so.6 "$_system"; fi
		if [ ! -e libm.so.6 ]; then dl libm.so.6 "$_system"; fi
		if [ ! -e libpthread.so.0 ]; then dl libpthread.so.0 "$_system"; fi
		if [ ! -e api.sh ]; then dl api.sh; fi
		# support alpine
		if [ ! -e libstdc++.so.6 ]; then dl libstdc++.so.6 "$_system"; fi
		# freebsd .. need to test
		# freebsd $(uname -o) FreeBSD, termux
                if [ ! -e libz.so.1 ]; then dl libz.so.1 "$_system"; fi
	;;
	x86-64_linux)
		if [ ! -e ld-linux-x86-64.so.2 ]; then dl ld-linux-x86-64.so.2 "$_system"; fi
		if [ ! -e libc.so.6 ]; then dl libc.so.6 "$_system"; fi
		if [ ! -e libm.so.6 ]; then dl libm.so.6 "$_system"; fi
		if [ ! -e api.sh ]; then dl api.sh; fi
		# support alpine
		if [ ! -e libpthread.so.0 ]; then dl libpthread.so.0 "$_system"; fi
		if [ ! -e libstdc++.so.6 ]; then dl libstdc++.so.6 "$_system"; fi
		# freebsd $(uname -o) FreeBSD, termux
		if [ ! -e libz.so.1 ]; then dl libz.so.1 "$_system"; fi
	;;
	armhf_raspbian)
		if [ ! -e ld-linux-armhf.so.3 ]; then dl ld-linux-armhf.so.3 "$_system"; fi
		if [ ! -e libc.so.6 ]; then dl libc.so.6 "$_system"; fi
		if [ ! -e libdl.so.2 ]; then dl libdl.so.2 "$_system"; fi
		if [ ! -e libm.so.6 ]; then dl libm.so.6 "$_system"; fi
		if [ ! -e librt.so.1 ]; then dl librt.so.1 "$_system"; fi
		if [ ! -e libutil.so.1 ]; then dl libutil.so.1 "$_system"; fi
		if [ ! -e libstdc++.so.6 ]; then dl libstdc++.so.6 "$_system"; fi
		if [ ! -e api.sh ]; then dl api.sh; fi
		# support alpine
		if [ ! -e libpthread.so.0 ]; then dl libpthread.so.0 "$_system"; fi
		if [ ! -e libstdc++.so.6 ]; then dl libstdc++.so.6 "$_system"; fi
		# freebsd need to test, termux
		if [ ! -e libz.so.1 ]; then dl libz.so.1 "$_system"; fi
	;;
	x86-64_windows)
		# no libs on windows
		:
	;;
	*)
		echo "$_system" not supported
		exit 1
	;;
esac



# perms
chmod +x ld-linux-x86-64.so.2 2>/dev/null
chmod +x ld-linux-aarch64.so.1 2>/dev/null
chmod +x ld-linux-armhf.so.3 2>/dev/null
chmod +x api.sh 2>/dev/null
chmod +x $_api 2>/dev/null


# add user
echo

# using proot for user

# finish
echo
echo starting api

case $_system in
	armhf_raspbian)
		_bin=ld-linux-armhf.so.3
	;;
	arm64_raspbian)
		_bin=./ld-linux-aarch64.so.1
	;;
	x86-64_linux)
		_bin=ld-linux-x86-64.so.2
	;;
	x86-64_windows)
		if [ ! "$_os" == "cygwin" ]
		then
			echo "$_system" not supported
			exit
		fi
	;;
	*)
		echo "$_system" not supported
		exit 1
	;;
esac

# todo test termux work wit out proot
if [ "$_os" == "cygwin" ]
then
	# fixing perm when giving to windows kernel
	chmod -R 777 "$_install_path"

	./$_api &
	while [ $_trap -eq 0 ]
	do
		sleep 5
	done
else
	mkdir -p proot-tmp
	chmod 777 proot-tmp
	export PROOT_TMP_DIR=proot-tmp

	# if root then run under telerising-script
	if [ $(./bin/id -u) -eq 0 ]
	then
		./bin/deluser $_user &>/dev/null
		./bin/adduser -h "$_install_path" -s /bin/sh -D $_user &>/dev/null
		./bin/chown -R $_user "$_install_path" &>/dev/null
		if [ ! $? -eq 0 ]
		then
			echo failed chown to $_user
			echo trying as root
			_proot_works=$(./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ls "$_install_path" 2>/dev/null)
			if [ "$_proot_works" == "" ]
			then
				>&2 echo proot fail.
				>&2 echo starting without proot. if this fail, then contact me with the output of the following lines.
				./ld-* ./api
			else
				./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ./ld-* ./api
			fi
		else
			_su_works=$(./bin/su $_user -p -c "ls '$_install_path'" 2>/dev/null)
			_proot_works=$(./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ls "$_install_path" 2>/dev/null)
			if [ ! "$_su_works" == "" ] && [ ! "$_proot_works" == "" ]
			then
				>&2 echo su and proot seems to work.
				>&2 echo starting. if this fail, then contact me with the output of the following lines.
				./bin/su $_user -p -c "./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ./ld-* ./api"
			elif [ ! "$_su_works" == "" ]
			then
				>&2 echo su seems to work but not proot.
				>&2 echo starting with su only. if this fail, then contact me with the output of the following lines.
				./bin/su $_user -p -c "./ld-* ./api"
			elif [ ! "$_proot_works" == "" ]
			then
				>&2 echo proot seems to work but not su.
				>&2 echo starting with proot only. if this fail, then contact me with the output of the following lines.
				./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ./ld-* ./api
			else
				>&2 echo proot and su not working on this system.
				>&2 echo starting. if this fail, then contact me with the output of the following lines.
				./ld-* ./api
			fi
		fi
		./bin/deluser $_user &>/dev/null
	else
		_proot_works=$(./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ls "$_install_path" 2>/dev/null)
		if [ ! "$_proot_works" == "" ]
		then
			>&2 echo proot seems to work.
			>&2 echo starting. if this fail, then contact me with the output of the following lines.
			./bin/$_system-proot --kill-on-exit --bind=. --bind=.:/usr/share/zoneinfo --bind=./resolv.conf:/etc/resolv.conf --bind=./hosts:/etc/hosts ./ld-* ./api
		else
			>&2 echo proot not working on this system.
			>&2 echo starting without proot. if this fail, then contact me with the output of the following lines.
			export PYTZ_TZDATADIR="/tmp/zoneinfo"
			echo "$_install_path"
			PYTZ_TZDATADIR="/tmp/zoneinfo" ./ld-* ./api
		fi
	fi
fi


exit $?
