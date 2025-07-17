#!/bin/bash

# todo:
#       dont wait providers if tr is disabled
#       escape json for http matrix
#       text escaping anywhere needed?
#       email
#       telegram curl
#       the most important things are included and are enough for me for now. more on request

_set=/telerising/settings.json
_pro=/telerising/app/static/json/providers.json
_pro_state=""

_idle=${HEALTH_INT-300}

_hook="$HEALTH_HOOK"
_hook_type="${HEALTH_HOOK_TYP:-J}"

_mqtt_host="$HEALTH_MQTT_HOST"
_mqtt_port="${HEALTH_MQTT_PORT-1883}"
_mqtt_topic="$HEALTH_MQTT_TOPIC"
_mqtt_type="${HEALTH_MQTT_TYP:-J}"

_matrix_url=$HEALTH_MATRIX_URL
_matrix_room=$HEALTH_MATRIX_ROOM
_matrix_token=HEALTH_MATRIX_TOKEN
_matrix_type="${HEALTH_MATRIX_TYP:-J}"

_kodi_url=$HEALTH_KODI_URL

_influx_url=$HEALTH_INFLUX_URL
_influx_bucket=$HEALTH_INFLUX_BUCK
_influx_org=$HEALTH_INFLUX_ORG
_influx_token=$HEALTH_INFLUX_TOKEN

_mqtt_enabled=0
_matrix_enabled=0
_influx_enabled=0

if [[ ! "$_idle" =~ ^[0-9]+$ ]]; then _idle=300; fi

if [[ ! "$_hook_type" =~ [JT] ]]; then _hook_type=J; fi
if [[ ! "$_mqtt_type" =~ [JT] ]]; then _mqtt_type=J; fi
if [[ ! "$_matrix_type" =~ [JT] ]]; then _matrix_type=J; fi

if [ ! "$_influx_url" == "" ] && [ ! "$_influx_bucket" == "" ] && [ ! "$_influx_org" == "" ] && [ ! "$_influx_token" == "" ]; then _influx_enabled=1; fi
if [ ! "$_mqtt_host" == "" ] && [ ! "$_mqtt_port" == "" ] && [ ! "$_mqtt_topic" == "" ]; then _mqtt_enabled=1; fi
if [ ! "$_matrix_url" == "" ] && [ ! "$_matrix_room" == "" ] && [ ! "$_matrix_token" == "" ]; then _matrix_enabled=1; fi

declare -A _pro_db
declare -A _msg_type

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
			_msg_type[T]="easyepg down: on host ($(hostname))"
			_msg_type[J]='{"health":"ERROR","name":"easyepg","id":"easyepg"}'
                        echo "easyepg down: on host ($(hostname))"
			if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "easyepg,host=$(hostname) value=0 $(date +%s%N)"
			if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
                        if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
			if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
                        rm -f /tmp/easyepg.status.ok
                        echo $(date +%s) > /tmp/easyepg.status.fail
                fi
        else
                if [ ! -e "/tmp/easyepg.status.ok" ]
                then
			_msg_type[T]="easyepg up: on host ($(hostname))"
			_msg_type[J]='{"health":"OK","name":"easyepg","id":"easyepg"}'
                        echo "easyepg up: on host ($(hostname))"
			if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "easyepg,host=$(hostname) value=1 $(date +%s%N)"
			if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
                        if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
			if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
                        echo $(date +%s) > /tmp/easyepg.status.ok
                        rm -f /tmp/easyepg.status.fail
                fi
        fi

	curl -s "http://127.0.0.1:$_port" &>/dev/null
	if [ $? -ne 0 ]
	then
		if [ ! -e "/tmp/telerising.status.fail" ]
		then
			_msg_type[T]="telerising down: on host ($(hostname))"
			_msg_type[J]='{"health":"ERROR","name":"telersing","id":"telerising"}'
			echo "telerising down: on host ($(hostname))"
			if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "telerising,host=$(hostname) value=0 $(date +%s%N)"
			if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
			if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
			rm -f /tmp/telerising.status.ok
			rm -f /tmp/telerising.status.*.*
			echo $(date +%s) > /tmp/telerising.status.fail
		fi
		sleep 60
		continue
	else
		if [ ! -e "/tmp/telerising.status.ok" ]
		then
			_msg_type[T]="telerising up: on host ($(hostname))"
			_msg_type[J]='{"health":"OK","name":"telersing","id":"telerising"}'
			echo "telerising up: on host ($(hostname))"
			if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "telerising,host=$(hostname) value=1 $(date +%s%N)"
			if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
			if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
			if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
			if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
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
				_msg_type[T]="telerising error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				_msg_type[J]='{"health":"ERROR","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'
	                        echo "telerising error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "$_name,host=$(hostname) value=0 $(date +%s%N)"
				if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
				if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
	                        echo $(date +%s) > "/tmp/telerising.status.$_name.fail"
				echo $_msg > "/tmp/telerising.msg.$_name"
	                        rm -f "/tmp/telerising.status.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_name.unk"
	                fi
	        elif [ "$_success" == "true" ] || [ "$_status" == "OK" ]
	        then
	                if [ ! -e "/tmp/telerising.status.$_name.ok" ]
	                then
				_msg_type[T]="telerising ok: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				_msg_type[J]='{"health":"OK","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'
	                        echo "telerising ok: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "$_name,host=$(hostname) value=2 $(date +%s%N)"
				if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
				if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
	                        echo $(date +%s) > "/tmp/telerising.status.$_name.ok"
	                        rm -f "/tmp/telerising.status.$_name.fail"
	                        rm -f "/tmp/telerising.status.$_name.unk"
				rm -f "/tmp/telerising.msg.$_name"
	                fi
	        else
	                if [ ! -e "/tmp/telerising.status.$_name.unk" ]
	                then
				_msg_type[T]="telerising unknown error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				_msg_type[J]='{"health":"UNKNOWN","name":"'"$_fullname"'","id":"'"$_name"'","msg":"'"$_msg"'"}'
	                        echo "telerising unknown error: on host ($(hostname)) id: $_name service: $_fullname status: ${_status:-$_success} message: $_msg"
				if [ _influx_enabled -eq 1 ]; then curl -q -XPOST "http://$_influx_url?bucket=$_influx_bucket&precision=ns&org=$_influx_org" --header "Authorization: Token $_influx_token" --data-raw "$_name,host=$(hostname) value=1 $(date +%s%N)"
				if [ ! "$_kodi_url" == "" ]; then curl -X POST -H 'Content-Type: application/json' -i $_kodi_url/jsonrpc --data '{"jsonrpc":"2.0","id":0,"method":"GUI.ShowNotification","params":{"title":"HealthCheck","message":"${_msg_type[T]}","displaytime":3000}}'; fi
				if [ ! "$_hook" == "" ]; then curl -s "$_hook" -d "${_msg_type[$_hook_type]}"; fi
				if [ $_mqtt_enabled -eq 1 ]; then mosquitto_pub -q 2 -h "$_mqtt_host" -p $_mqtt_port -m "${_msg_type[$_mqtt_type]}"; fi
				if [ $_matrix_enabled -eq 1 ]; then curl -d '{"msgtype":"m.text", "body":"${_msg_type[$_matrix_type]}"}' "https://$_matrix_url/_matrix/client/r0/rooms/$_matrix_room/send/m.room.message?access_token=$_matrix_token"; fi
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
