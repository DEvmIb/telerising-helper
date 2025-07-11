#/bin/bash
# todo:
#  - freebsd: check if fbsd has v6 v7 v8 and add libs
#  - when ~ /root then not use /root. (perms)
#  - all pkg no cache..
#  - proot: resolv.conf zones hosts
#  - busybox for find when miss
_mirror=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main
_sub=
_install_path=${1:-~/telerising}
_system=$(echo $2)
_os=$(uname -o)
_kernel=$(uname -s)
_machine=$(uname -m)

_os=${_os,,}
_kernel=${_kernel,,}
_machine=${_machine,,}

_api=api

if [ "$1" == "-d" ] || [ "$1" == "--devices" ]
then
	echo "####################################################################################################"
	echo "#                                                                                                  #"
	echo "#                                     tested devices                                               #"
	echo "#                                                                                                  #"
	echo "#      * Windows 10 / 11                                                                           #"
	echo "#        - wls1         | debian, ubuntu                                                           #"
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
	echo "####################################################################################################"
	echo "#                                                                                                  #"
	echo "# usage: [install_dir] [system]                                                                    #"
	echo "#                                                                                                  #"
	echo "# this script needs root for then following tasks:                                                 #"
	echo "#    - install tzdata       | if not exists in /usr/share/zonedata                                 #"
	echo "#    - modifying /etc/hosts | telerising needs to resolve our own hostname                         #"
	echo "#    - add user             | if possible create user telerising else run under root               #"
	echo "#    - package system       | if available try to install needed packages                          #"
	echo "#                                                                                                  #"
	echo "#                                                                                                  #"
	echo "# system tools needed:                                                                             #"
	echo "#    - wget or curl                                                                                #"
	echo "#    - tar                                                                                         #"
	echo "#    - unzip                                                                                       #"
	echo "#    - bash                                                                                        #"
	echo "#                                                                                                  #"
	echo "# params:                                                                                          #"
	echo "#    - install_dir | where should telerising be installed | default [~/telerising]                 #"
	echo "#    - systems:                                                                                    #"
	echo "#      - empty          | try to autodetect                                                        #"
	echo "#      - arm64_raspbian | arm64 devices                                                            #"
	echo "#      - x86-64_linux   | amd64 devices                                                            #"
	echo "#      - armhf_raspbian | armhf devices                                                            #"
	echo "#      - x86-64_windows | windows 64bit                                                            #"
	echo "#                                                                                                  #"
	echo "# other:                                                                                           #"
	echo "#    - install modified providers.json for waipu support                                           #"
	echo "#    - put you own modified providers.json into [install_dir] to use it instead                    #"
	echo "#                                                                                                  #"
	echo "# examples:                                                                                        #"
	echo "#                                                                                                  #"
	echo "# curl -s http://216.225.197.57:63142/newenigma/api.sh|bash -s -- /opt/telerising arm64_raspbian   #"
	echo "# curl -s http://216.225.197.57:63142/newenigma/api.sh|bash -s -- /opt/telerising x86-64_linux     #"
	echo "# curl -s http://216.225.197.57:63142/newenigma/api.sh|bash -s -- /opt/telerising armhf_raspbian   #"
	echo "#                                                                                                  #"
	echo "# support on kodinerds https://www.kodinerds.net/wcf/user/32559-fds97avvs/                         #"
	echo "#                                                                                                  #"
	echo "####################################################################################################"
	exit 0
fi

function host_name {
	local _host
	_host=$(hostname 2>/dev/null)
	if [ "$_host" == "" ]
	then
		_host=$(uname -n 2>/dev/null)
	fi
	if [ "$_host" == "" ]
	then
		_host=$(cat /etc/hostname 2>/dev/null)
	fi
	if [ "$_host" == "" ]
	then
                _host=localhost
        fi
	echo "$_host"
}

function dloader {
	local _bin
	if hash wget &>/dev/null; then _bin=wget; else if hash curl &>/dev/null; then _bin=curl; fi; fi
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
	if [ "$_bin" == "wget" ]
	then
		wget "$_url" &>/dev/null
		if [ $? -ne 0 ]; then >&2 echo "failed downloading $1"; rm -f "$1"; exit 1; fi
	else
		curl -LO "$_url" &>/dev/null
		if [ $? -ne 0 ]; then >&2 echo "failed downloading $1"; rm -f "$1"; exit 1; fi
	fi
}

function update {
	local _latest _ver _file _api_search _api_path _del
	if ! hash unzip 2>/dev/null; then >&2 echo missing unzip, please install; exit 1; fi
	_latest=$(curl -s https://api.github.com/repos/sunsettrack4/telerising-api/releases/latest 2>/dev/null)
	if [[ ! "$_latest" =~ /releases/download/v([.0-9]+)/telerising-v[.0-9]+_$_system\.zip ]]
	then
		if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
		>&2 echo update check failed
		return
	fi
	_ver=${BASH_REMATCH[1]}
	_file=telerising-v${_ver}_$_system.zip
	if [ "$(cat installed.ver 2>/dev/null)" == "$_ver" ]
	then
		>&2 echo update not needed v$_ver
		return
	fi
	dl https://github.com/sunsettrack4/telerising-api/releases/download/v$_ver/$_file
	rm -rf tmp
	mkdir -p tmp
	>&2 echo extracting..
	unzip -o $_file -d tmp &>/dev/null
	if [ $? -ne 0 ]
	then
		>&2 echo error extract.
		rm -f $_file
		if [ ! -e "$_install_path/$_api" ]; then >&2 echo failed getting current version; exit 1; fi
		return
	fi
	_api_search=$(find tmp -name $_api)
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
	for _kill in ld-linux-x86-64.so.2 ld-linux-armhf.so.3 ld-linux-aarch64.so.1
	do
		# try all ways without check if any app exists
		if hash kill pgrep &>/dev/null
		then
			kill $(pgrep -f $_kill 2>/dev/null) &>/dev/null
		elif hash kill pidof &>/dev/null
		then
			kill $(pidof $_kill 2>/dev/null) &>/dev/null
		elif hash killall &>/dev/null
		then
			killall $_kill &>/dev/null
		elif hash pkill &>/dev/null
		then
			pkill -f $_kill &>/dev/null
		elif hash grep kill &>/dev/null
		then
			# find in proc
			_r=$(grep ${_kill%%.*} /proc/*/status 2>/dev/null)
			if [[ "$_r" =~ /proc/([0-9]+)/status: ]]
			then
				_pid=${BASH_REMATCH[1]}
				kill $_pid
			fi
		fi
	done
	_trap=1
	exit 1
}

if [[ -t 1 ]]
then
	_auto=0
else
	_auto=1
fi

if [[ "$(export)" =~ com\.termux ]]
then
	_os=termux
fi

# perms check

if [ "$_os" == "cygwin" ]
then
	# cygwin no root needed
	>&2 echo running under cygwin
elif [ "$_os" == "termux" ]
then
	# termux no root
	>&2 echo running under termux
elif [ $(id -u) -ne 0 ]
then
	echo we need root sorry.
	exit 1
fi

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
if [[ "$_install_path" == *"/tmp/"* ]]; then >&2 echo warning if you install into tmp you telerising settings may be deleted on next reboot; sleep 2; fi


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

# package systems
echo
if hash zypper &>/dev/null
then
	# suse
	echo found zypper
	for _pkg in timezone curl wget su sudo unzip psmisc find
	do
		echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
		zypper install -y $_pkg &>/dev/null
		if [ $? -eq 0 ]; then echo ok; else echo fail; fi
	done
elif hash yum &>/dev/null
then
	# fedora centos ..
	echo found yum.
	for _pkg in tzdata curl wget su sudo unzip
	do
		echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
		yum -y install $_pkg &>/dev/null
		if [ $? -eq 0 ]; then echo ok; else echo fail; fi
	done
elif hash apt &>/dev/null
then
        # debian based ..
        echo found apt.
	echo -en "\t -update: "
	apt update &>/dev/null
	if [ $? -eq 0 ]; then echo ok; else echo fail; fi
	# proot for termux
        for _pkg in tzdata curl wget su sudo unzip proot
        do
                echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
                apt -y install $_pkg &>/dev/null
                if [ $? -eq 0 ]; then echo ok; else echo fail; fi
        done
elif hash apk &>/dev/null
then
        # alpine based ..
        echo found apk.
        for _pkg in tzdata curl wget su sudo unzip
        do
                echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
                apk add --no-cache $_pkg &>/dev/null
                if [ $? -eq 0 ]; then echo ok; else echo fail; fi
        done
elif hash pkg &>/dev/null
then
	# freebsd ..
	echo found pkg.
	for _pkg in tzdata curl wget su sudo unzip
	do
		echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
		pkg install -y $_pkg &>/dev/null
		if [ $? -eq 0 ]; then echo ok; else echo fail; fi
	done
elif hash microdnf &>/dev/null
then
	# rocky
	echo found microdnf.
	for _pkg in tzdata curl wget su sudo unzip findutils
	do
		echo -en "\t -$_pkg: "
		if hash $_pkg &>/dev/null; then echo ok; continue; fi
		microdnf install -y $_pkg &>/dev/null
		if [ $? -eq 0 ]; then echo ok; else echo fail; fi
	done
else
	echo no supported package manager found.
fi

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
	echo -n "update telersing?. auto skipping in 5s. (y/N): "
        if [ $_auto -eq 1 ]
	then
		_install=y
	else
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
echo -n "install modified providers.json for waipu support? skipping in 5s. (y/N): "
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

# hostname check
echo
_r=$(grep "^127.0.0.1 $(host_name)" /etc/hosts)
if [ "$_r" == "" ] && [ ! "$_os" == "termux" ]
then
	>&2 echo "setting hostname in /etc/hosts"
	echo 127.0.0.1 $(host_name) >> /etc/hosts &>/dev/null
	if [ $? -ne 0 ]
	then
		# will fail on cygwin todo: removing the sym and create hosts?
		>&2 echo failed setting /etc/hosts
	fi
fi

# zone data
echo
if [ ! -e /usr/share/zoneinfo/tzdata.zi ] && [ ! "$_os" == "termux" ]
then
	echo "installing tzdata: tzdata.zi"
	rm -f zoneinfo.tar.gz
	mkdir -p /usr/share/zoneinfo &>/dev/null
	if [ $? -ne 0 ]; then echo error creating /usr/share/zoneinfo; exit 1; fi
	if [ ! -e tzdata.zi ]; then dl tzdata.zi; fi
	cp tzdata.zi /usr/share/zoneinfo/ &>/dev/null
fi

if [ ! -e /usr/share/zoneinfo/zone1970.tab ] && [ ! "$_os" == "termux" ]
then
	echo "installing tzdata: zone1970.tab"
	mkdir -p /usr/share/zoneinfo
	if [ $? -ne 0 ]; then echo error creating /usr/share/zoneinfo; exit 1; fi
	if [ ! -e zone1970.tab ]; then dl zone1970.tab; fi
	cp zone1970.tab /usr/share/zoneinfo/ &>/dev/null
fi

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

# rewrite
if [ "$(id telerising-script 2>/dev/null)" == "" ]
then
	pw useradd telerising-script -d "$_install_path" &>/dev/null
fi

if [ "$(id telerising-script 2>/dev/null)" == "" ]
then
	useradd -d "$_install_path" -s /bin/false telerising-script &>/dev/null
fi

if [ "$(id telerising-script 2>/dev/null)" == "" ] && [ -e /etc/passwd ] && [ -e /etc/group ] && [ ! "$_os" == "termux" ]
then
	for _id in {1000..2000}
	do
		if [[ ! "$_ids" == *":$_id:"* ]] && [[ ! "$_groups" == *":$_id:"* ]]
		then
			echo "telerising-script:x:$_id:$_id:,,,:/opt/telerising:/bin/false" >> /etc/passwd
			echo "telerising-script:x:$_id:" >> /etc/group
			if [ -e /etc/shadow ]
			then
				echo "telerising-script:!:20279:0:99999:7:::" >> /etc/shadow
			fi
			break
		fi
	done
fi

if [ ! "$(id telerising-script 2>/dev/null)" == "" ]; then chown -R telerising-script "$_install_path"; fi

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

if [ "$_os" == "termux" ]
then
	if ! hash proot &>/dev/null; then >&2 echo proot is needed under termux; exit 1; fi
	if [ ! -e tzdata.zi ]; then dl tzdata.zi; fi
	if [ ! -e zone1970.tab ]; then dl zone1970.tab; fi
	cat /etc/hosts > hosts
	echo "127.0.0.1 $(host_name)" >> hosts
	unset LD_PRELOAD
	proot --bind=. --bind=.:/usr/share/zoneinfo --bind=.:/etc ./ld-* ./api
elif [ "$_os" == "cygwin" ]
then
	# fixing perm when giving to windows kernel
	chmod -R 777 "$_install_path"

	./$_api &
	while [ $_trap -eq 0 ]
	do
		sleep 5
	done
elif [ $(su -m telerising-script -c "ls $_install_path" 2>/dev/null|wc -l) -ne 0 ]
then
	echo su found
	>&2 su -m telerising-script -c "./$_bin ./$_api"
elif [ $(su -s /bin/sh telerising-script -c "ls $_install_path" 2>/dev/null|wc -l) -ne 0 ]
then
	echo su found
	>&2 su -s /bin/sh telerising-script -c "./$_bin ./$_api"
elif [ $(su -s /bin/ls telerising-script "$_install_path" 2>/dev/null|wc -l) -ne 0 ]
then
        echo su found
        >&2 su -s ./$_bin telerising-script ./$_api
elif [ $(sudo -u telerising-script ls "$_install_path" 2>/dev/null|wc -l) -ne 0 ]
then
        echo sudo found
        >&2 sudo -u telerising-script bash -c "cd '$_install_path'; ./$_bin ./$_api"
else
        echo cannot start as telerising user. running telerising as root
        >&2 ./$_bin ./$_api
fi


exit $?
