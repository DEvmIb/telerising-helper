#!/bin/bash
export PYTHONUNBUFFERED=1
export NO_PROXY=localhost,127.0.0.1,localhost.localdomain,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,fd00::/8,fe80::/8

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

if [ "$HEALTH_DISABLE" == "" ]; then screen -dmS healt-check bash -c 'while :; do date +%s > /tmp/health-check.up; wget -qO - https://github.com/DEvmIb/telerising-helper/blob/main/docker-aio/health-check.sh|bash -s >> /tmp/health-check.log 2>&1; sleep 10; done'; fi

wget -q https://github.com/DEvmIb/telerising-helper/blob/main/docker-aio/health-socat.sh -O /tmp/health-socat.sh
wget -q https://github.com/DEvmIb/telerising-helper/blob/main/docker-aio/health-socat-html.sh -O /tmp/health-socat-html.sh

chmod +x /tmp/health-socat.sh
chmod +x /tmp/health-socat-html.sh

screen -dmS socat bash -c 'while :; do socat -v -d -d TCP-LISTEN:3000,crlf,reuseaddr,fork SYSTEM:"bash /tmp/health-socat.sh" ; sleep 10; done'
screen -dmS socat bash -c 'while :; do socat -v -d -d TCP-LISTEN:3001,crlf,reuseaddr,fork SYSTEM:"bash /tmp/health-socat-html.sh" ; sleep 10; done'

sleep infinity
