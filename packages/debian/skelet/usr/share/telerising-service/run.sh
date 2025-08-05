#/bin/bash

_opt=/usr/share/telerising-service
_etc=/etc/telerising-service
_url=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main

export TR_SETTINGS=$_etc/settings.json
export TR_PROVIDERS=$_etc/providers.json
export TR_COOKIES=$_etc/cookie_files
export TR_VERSION={version}

if [ $(pgrep -f "^./ld-.* ./api$"|wc -l) -eq 0 ]
then
    curl -s $_url/api.sh|bash -s -- $_opt
fi
