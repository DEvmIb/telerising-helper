#!/bin/bash

_set=/telerising/settings.json
_pro=/telerising/app/static/json/providers.json
_pro_state=""
_idle=${HEALTH_INT-300}
_hook="$HEALTH_HOOK"
_mqtt_host="$HEALTH_MQTT_HOST"
_mqtt_port="${HEALTH_MQTT_PORT-1883}"
_mqtt_topic="$HEALTH_MQTT_TOPIC"
_mqtt_enabled=0

if [ ! "$_mqtt_host" == "" ] && [ ! "$_mqtt_port" == "" ] && [ ! "$_mqtt_topic" == "" ]; then _mqtt_enabled=1; fi

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
	_port=$(jq -r '.basic|select(.port!=null)|.port' "$_set" 2>/dev/null)
	_port=${_port:-5000}
	_pass=$(jq -r '.basic|select(.password!=null)|.password' "$_set" 2>/dev/null)
	if [ "$_pass" == "" ]
	then
		# no pass set atm waiting
		sleep 60
		continue
	fi
	_pro_db_build

        curl -s "http://127.0.0.1:4000" &>/dev/null
        if [ $? -ne 0 ]
        then
                if [ ! -e "/tmp/easyepg.status.fail" ]
                then
                        echo "easyepg down: on host ($(hostname))"
                        if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"ERROR","name":"easyepg","id":"easyepg"}'; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"ERROR","name":"easyepg","id":"easyepg"}'; fi
                        rm -f /tmp/easyepg.status.ok
                        echo $(date +%s) > /tmp/easyepg.status.fail
                fi
        else
                if [ ! -e "/tmp/easyepg.status.ok" ]
                then
                        echo "easyepg up: on host ($(hostname))"
                        if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"OK","name":"easyepg","id":"easyepg"}'; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"OK","name":"easyepg","id":"easyepg"}'; fi
                        echo $(date +%s) > /tmp/easyepg.status.ok
                        rm -f /tmp/easyepg.status.fail
                fi
        fi

	curl -s "http://127.0.0.1:$_port" &>/dev/null
	if [ $? -ne 0 ]
	then
		if [ ! -e "/tmp/telerising.status.fail" ]
		then
			echo "telerising down: on host ($(hostname))"
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"ERROR","name":"telersing","id":"telerising"}'; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"ERROR","name":"telersing","id":"telersing"}'; fi
			rm -f /tmp/telerising.status.ok
			rm -f /tmp/telerising.status.*.*
			echo $(date +%s) > /tmp/telerising.status.fail
		fi
		sleep 60
		continue
	else
		if [ ! -e "/tmp/telerising.status.ok" ]
		then
			echo "telerising up: on host ($(hostname))"
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"OK","name":"telersing","id":"telerising"}'; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"OK","name":"telersing","id":"telersing"}'; fi
			echo $(date +%s) > /tmp/telerising.status.ok
			rm -f /tmp/telerising.status.fail
		fi
	fi

	curl -s -b /tmp/check-cookies.cookies -c /tmp/check-cookies.cookies "http://127.0.0.1:$_port/api/login_check" --data-raw "pw=$_pass" &>/dev/null
	_data=$(curl -s -b /tmp/check-cookies.cookies -c /tmp/check-cookies.cookies "http://127.0.0.1:$_port"|grep 'var test =')
	_data=${_data:15}
	while read -r _line
	do
	        IFS='|' read -ra _data <<<"$_line"
	        _name=${_data[0]}
		_fullname=${_pro_db[$_name]}
	        _success=${_data[1]}
	        _status=${_data[2]}
	        _msg=${_data[3]}
	        if [ "$_success" == "false" ] || [ "$_status" == "ERROR" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_name.fail" ]
	                then
	                        echo "telerising error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"ERROR","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"ERROR","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
	                        echo $(date +%s) > "/tmp/telerising.status.$_name.fail"
				echo $_msg > "/tmp/telerising.msg.$_name"
	                        rm -f "/tmp/telerising.status.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_name.unk"
	                fi
	        elif [ "$_success" == "true" ] || [ "$_status" == "OK" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_name.ok" ]
	                then
	                        echo "telerising ok: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"OK","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"OK","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
	                        echo $(date +%s) > "/tmp/telerising.status.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_name.unk"
				rm -f "/tmp/telerising.msg.$_name"
	                fi
	        else
	                if [ ! -e "/tmp/telerising.status.$_name.unk" ]
	                then
	                        echo "telerising unknown error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d '{"health":"UNKNOWN","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m '{"health":"UNKNOWN","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'; fi
	                        echo $(date +%s) > "/tmp/telerising.status.$_name.unk"
				echo $_msg > "/tmp/telerising.msg.$_name"
	                        rm -f "/tmp/telerising.status.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_name.fail"
	                fi
	        fi
	#done < <(echo "$_data"|jq -cr 'keys[] as $k | $k')
	done < <(echo "$_data"|jq -cr 'keys[] as $k | $k+"|"+(.[$k].success|tostring|gsub("^null$";""))+"|"+(.[$k].status|tostring|gsub("^null$";""))+"|"+(.[$k].message|tostring|gsub("^null$";"")|gsub("\n";""))')
	sleep $_idle
done
