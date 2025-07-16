#!/bin/bash

echo "HTTP/1.1 200 OK"
echo "Content-Type: text/html"
echo

echo '<meta name="viewport" content="width=device-width, initial-scale=1">'

_providers=/telerising/app/static/json/providers.json

_red='#bd3333'
_green='#4a9e39'

if [ ! -e "$_providers" ]
then
	echo 'waiting for telerising installed'
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



if [ -e /tmp/telerising.status.ok ] && [ $(ps auxww|grep '[0-9]\s[.]/ld-.*\s\./api$'|wc -l) -eq 1 ]
then
	echo '
	<center>
	<table class="ck-table-resized" style="height: 110px;" width="372"><caption style="background:'"$_green"'"><strong>Telerising</strong></caption><colgroup><col style="width: 23.57%;" /><col style="width: 76.43%;" /></colgroup>
	<tbody>
	<tr>
	<td style="width: 40.6167px;">State</td>
	<td style="width: 140.683px;"><span style="color: #689f38;">up</span></td>
	</tr>
	<tr>
	<td style="width: 40.6167px;">Since</td>
	<td style="width: 140.683px;">'"$(date -d @$(cat /tmp/telerising.up))"'</td>
	</tr>
	</tbody>
	</table>
	</center>
	'
else
	echo '<center>
	<table class="ck-table-resized" style="height: 110px;" width="372"><caption style="background:'"$_red"'"><strong>Telerising</strong></caption><colgroup><col style="width: 23.57%;" /><col style="width: 76.43%;" /></colgroup>
	<tbody>
	<tr>
	<td style="width: 40.6167px;">State</td>
	<td style="width: 140.683px;"><span style="color: #00ffff;">Down</span></td>
	</tr>
	<tr>
	<td style="width: 40.6167px;">Since</td>
	<td style="width: 140.683px;">'"$(date -d @$(cat /tmp/telerising.up))"'</td>
	</tr>
	</tbody>
	</table>
	</center>'
fi

if [ -e /tmp/easyepg.up ] && [ $(ps auxww|grep '[p]ython main.py$'|wc -l) -eq 1 ]
then
        echo '
        <center>
        <table class="ck-table-resized" style="height: 110px;" width="372"><caption style="background:'"$_green"'"><strong>Easyepg</strong></caption><colgroup><col style="width: 23.57%;" /><col style="width: 76.43%;" /></colgroup>
        <tbody>
        <tr>
        <td style="width: 40.6167px;">State</td>
        <td style="width: 140.683px;"><span style="color: #689f38;">up</span></td>
        </tr>
        <tr>
        <td style="width: 40.6167px;">Since</td>
        <td style="width: 140.683px;">'"$(date -d @$(cat /tmp/easyepg.up))"'</td>
        </tr>
        </tbody>
        </table>
        </center>
        '
else
        echo '<center>
        <table class="ck-table-resized" style="height: 110px;" width="372"><caption style="background:'"$_red"'"><strong>Easyepg</strong></caption><colgroup><col style="width: 23.57%;" /><col style="width: 76.43%;" /></colgroup>
        <tbody>
        <tr>
        <td style="width: 40.6167px;">State</td>
        <td style="width: 140.683px;"><span style="color: #00ffff;">Down</span></td>
        </tr>
        <tr>
        <td style="width: 40.6167px;">Since</td>
        <td style="width: 140.683px;">'"$(date -d @$(cat /tmp/telerising.up))"'</td>
        </tr>
        </tbody>
        </table>
        </center>'
fi

while read _state
do
	[[ "$_state" =~ ^/tmp/telerising\.status\.(.*)\.(.*)$ ]]
	_id=${BASH_REMATCH[1]}
	_state_service=${BASH_REMATCH[2]}
	_name=${_providers_db[$_id]}
	if [ "$_state_service" == "ok" ]; then _color=$_green; else _color=$_red; fi
        echo '
        <center>
        <table class="ck-table-resized" style="height: 110px;" width="372"><caption style="background:'"$_color"'"><strong>'"$_name"'</strong></caption><colgroup><col style="width: 23.57%;" /><col style="width: 76.43%;" /></colgroup>
        <tbody>
        <tr>
        <td style="width: 40.6167px;">State</td>
        <td style="width: 140.683px;"><span style="color: #689f38;">'"$_state_service"'</span></td>
        </tr>
        <tr>
        <td style="width: 40.6167px;">Msg</td>
        <td style="width: 140.683px;">'"$(cat /tmp/telerising.msg.$_id 2>/dev/null)"'</td>
        </tr>
        <tr>
        <td style="width: 40.6167px;">Since</td>
        <td style="width: 140.683px;">'"$(date -d @$(cat $_state))"'</td>
        </tr>
        </tbody>
        </table>
        </center>
        '
done < <(ls /tmp/telerising.status.*.*)



