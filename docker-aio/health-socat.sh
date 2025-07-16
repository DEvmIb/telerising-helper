#!/bin/bash

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json"
echo

_providers=/telerising/app/static/json/providers.json

if [ ! -e "$_providers" ]
then
	echo '{"code":1,"msg":"waiting for telerising installed"}'
	exit
fi

declare -A _providers_db
while read -r _line
do
        _data=($_line)
        _id=${_data[0]}
        _name=${_line:${#_id}+1}
        _providers_db[$_id]=$_name
done < <(jq -cr 'keys[] as $k | $k+" "+(.[$k].name|tostring)' "$_providers")


echo '{"code":0,"msg":"health check working",'

if [ -e /tmp/telerising.status.ok ] && [ $(ps auxww|grep '[0-9]\s[.]/ld-.*\s\./api$'|wc -l) -eq 1 ]
then
	echo '"telerising":{"state":"up","since":"'"$(cat /tmp/telerising.up)"'","since_human":"'"$(date -d @$(cat /tmp/telerising.up))"'"},'
else
	echo '"telerising":{"state":"down"},'
fi

if [ $(ps auxww|grep '[p]ython main.py$'|wc -l) -eq 0 ] || [ -e /tmp/easyepg.status.fail ]
then
	echo '"easyepg":{"state":"down"},'
else
	echo '"easyepg":{"state":"up","since":"'"$(cat /tmp/easyepg.up)"'","since_human":"'"$(date -d @$(cat /tmp/easyepg.up))"'"},'
fi

while read _state
do
	[[ "$_state" =~ ^/tmp/telerising\.status\.(.*)\.(.*)$ ]]
	_id=${BASH_REMATCH[1]}
	_state_service=${BASH_REMATCH[2]}
	_name=${_providers_db[$_id]}
	echo '"'"$_id"'":{"state":"'"$_state_service"'","name":"'"$_name"'","since":"'"$(cat $_state)"'","since_human":"'"$(date -d @$(cat $_state))"'"},'
done < <(ls /tmp/telerising.status.*.*)

echo '"time":"'"$(date +%s)"'","time_human":"'"$(date)"'"'

echo "}"
