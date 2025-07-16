#!/bin/bash

_set=/telerising/settings.json
_pro=/telerising/app/static/json/providers.json
_pro_state=""
_idle=300
_hook="$HEALTH_HOOK"

declare -A _pro_db

#prividers id to name db build
function _pro_db_build {
	local _data _line _id _name _state
	_state=$(stat "$_pro")
	if [ "$_state" == "$_pro_state" ]; then return; fi
	_pro_state="$_state"
	while read -r _line
	do
		_data=($_line)
		_id=${_data[0]}
		_name=${_line:${#_id}+1}
		_pro_db[$_id]=$_name
	done < <(jq -cr 'keys[] as $k | $k+" "+(.[$k].name|tostring)' "$_pro")
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
	_pro_db_build
	curl -s -b /tmp/check-cookies-$_port.cookies -c /tmp/check-cookies-$_port.cookies "http://127.0.0.1:$_port/api/login_check" --data-raw "pw=$_pass" >/dev/null
	if [ $? -ne 0 ]
	then
		if [ ! -e "/tmp/telerising.status.fail" ]
		then
			echo "telerising down: on host ($(hostname):$_port)"
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"ERROR","name":"telersing","id":"telerising"}'; fi
			rm -f /tmp/telerising.status.ok
		fi
		sleep 60
		continue
	else
		if [ ! -e "/tmp/telerising.status.ok" ]
			echo "telerising up: on host ($(hostname):$_port)"
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"OK","name":"telersing","id":"telerising"}'; fi
			rm -f /tmp/telerising.status.fail
		fi
	fi
	_data=$(curl -s -b /tmp/check-cookies-$_port.cookies -c /tmp/check-cookies-$_port.cookies "http://127.0.0.1:$_port"|grep 'var test =')
	_data=${_data:15}
	echo "$_data"|jq -cr
	while read -r _line
	do
	        IFS='|' read -ra _data <<<"$_line"
	        _name=${_data[0]}
		_fullname=${_pro_db[$_name]}
	        _success=${_data[1]}
	        _status=${_data[2]}
	        _msg=${_data[3]}
	        echo $_name - ${_status:-$_success} - $_msg
	        if [ "$_success" == "false" ] || [ "$_status" == "ERROR" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.fail" ]
	                then
	                        echo "telerising error: on host ($(hostname):$_port) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"ERROR","name":"'"$_fullname"'","id":"'"$_name"'"}'; fi
	                        touch "/tmp/telerising.status.$_port.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.unk"
	                fi
	        elif [ "$_success" == "true" ] || [ "$_status" == "OK" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.ok" ]
	                then
	                        echo "telerising ok: on host ($(hostname):$_port) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"OK","name":"'"$_fullname"'","id":"'"$_name"'"}'; fi
	                        touch "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_port.$_name.unk"
	                fi
	        else
	                if [ ! -e "/tmp/telerising.status.$_port.$_name.unk" ]
	                then
	                        echo "telerising unknown error: on host ($(hostname):$_port) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"UNKNOWN","name":"'"$_fullname"'","id":"'"$_name"'"}'; fi
	                        touch "/tmp/telerising.status.$_port.$_name.unk"
	                        rm -f "/tmp/telerising.status.$_port.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_port.$_name.fail"
	                fi
	        fi
	#done < <(echo "$_data"|jq -cr 'keys[] as $k | $k')
	done < <(echo "$_data"|jq -cr 'keys[] as $k | $k+"|"+(.[$k].success|tostring|gsub("^null$";""))+"|"+(.[$k].status|tostring|gsub("^null$";""))+"|"+(.[$k].message|tostring|gsub("^null$";"")|gsub("\n";""))')
	sleep $_idle
done
