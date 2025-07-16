#!/bin/sh
export PYTHONUNBUFFERED=1
apk add --no-cache bash py3-bottle py3-requests py3-xmltodict git jq curl screen socat tzdata mosquitto-clients

mkdir -p /telerising
mkdir -p /easyepg

cd /easyepg
git clone https://github.com/sunsettrack4/script.service.easyepg-lite
cd script.service.easyepg-lite
git pull

mv /easyepg/easyepg.log /easyepg/easyepg.$(date +%s).log &>/dev/null
mv /telerising/telerising.log /telerising/telerising.$(date +%s).log &>/dev/null

tail -n0 -F /easyepg/easyepg.log /telerising/telerising.log /telerising/exception.txt /tmp/health-check.log 2>/dev/null &

screen -wipe

if [ "$EPG_DISABLE" == "" ]; then screen -dmS easyepg bash -c 'while :; do date +%s > /tmp/easyepg.up; python main.py >> /easyepg/easyepg.log 2>&1; sleep 10; done'; fi

if [ "$TR_DISABLE" == "" ]; then screen -dmS telerising bash -c 'while :; do date +%s > /tmp/telerising.up; wget -qO - https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main/api.sh|exec bash -s -- /telerising >> /telerising/telerising.log 2>&1; sleep 10; done'; fi

if [ "$HEALTH_DISABLE" == "" ]; then screen -dmS healt-check bash -c 'while :; do date +%s > /tmp/health-check.up; /usr/local/bin/health-check.sh >> /tmp/health-check.log 2>&1; sleep 10; done'; fi

screen -dmS socat bash -c 'while :; do socat -v -d -d TCP-LISTEN:3000,crlf,reuseaddr,fork SYSTEM:"bash /usr/local/bin/health-socat.sh" ; sleep 10; done'
screen -dmS socat bash -c 'while :; do socat -v -d -d TCP-LISTEN:3001,crlf,reuseaddr,fork SYSTEM:"bash /usr/local/bin/health-socat-html.sh" ; sleep 10; done'
