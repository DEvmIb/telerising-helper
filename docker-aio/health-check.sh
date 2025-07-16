#!/bin/bash

_set=/telerising/settings.json
_pro=/telerising/app/static/json/providers.json
_idle=300
_hook="$HEALTH_HOOK"

declare -A _pro_db

#prividers id to name db build
function _pro_db_build {
	local _line _id _name
	unset $_pro_db
	declare -A _pro_db
	while read -r _line
	do
		
	done
}

# waiting for providers json
while :
do
	if [ -e "$_pro" ]; then break; fi
	sleep 10
done



while :
do
	_port=$(jq -r '.basic|select(.port!=null)|.port' "$_set")
	_port=${_port:-5000}
	_pass=$(jq -r '.basic|select(.password!=null)|.password' "$_set")
	if [ "$_pass" == "" ]
	then
		# no pass set atm waiting
		sleep 60
		continue
	fi
	curl -s -b /tmp/check-cookies-$_port.cookies -c /tmp/check-cookies-$_port.cookies "http://127.0.0.1:$_port/api/login_check" --data-raw "pw=$_pass" >/dev/null
	_data=$(curl -s -b /tmp/check-cookies-$_port.cookies -c /tmp/check-cookies-$_port.cookies "http://127.0.0.1:$_port"|grep 'var test =')
	_data=${_data:15}
	while read -u4 -r _line
	do
	        IFS='|' read -ra _data <<<"$_line"
	        _name=${_data[0]}
	        _success=${_data[1]}
	        _status=${_data[2]}
	        _msg=${_data[3]}
	        echo $_name - ${_status:-$_success} - $_msg
	        if [ "$_success" == "false" ] || [ "$_status" == "ERROR" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.fail" ]
	                then
	                        #push "telerising error: on host ($(hostname):$_port) service: $_name status: $_status message: $_msg"
				if [ ! "$_health" == "" ]; then curl 
	                        touch "/tmp/telerising.status.$_port.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.unk"
	                fi
	        elif [ "$_success" == "true" ] || [ "$_status" == "OK" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.ok" ]
	                then
	                        #push "telerising ok: on host ($(hostname):$_port) service: $_name status: $_status message: $_msg"
	                        touch "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_port.$_name.unk"
	                fi
	        else
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.unk" ]
	                then
	                        #push "telerising unknown error: on host ($(hostname):$_port) service: $_name status: ${_status:-$_success} message: $_msg"
	                        touch "/tmp/telerising.status.$_port.$_name.unk"
	                        rm -f "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.fail"
	                fi
	        fi
	done 4< <(echo "$_data"|jq -cr 'keys[] as $k | $k+"|"+(.[$k].success|tostring)+"|"+.[$k].status+"|"+(.[$k].message|gsub("\n";""))')
	sleep $_idle
done
