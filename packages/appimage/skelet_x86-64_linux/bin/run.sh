echo;echo;echo
echo "######################################################"
echo "           telerising AppImage by Ad0lar             #"
echo "      https://matrix.to/#/#telerising:matrix.org     #"
echo "                                                     #"
echo "######################################################"
echo;echo;echo

_fail=0

if [ $(id -u) -eq 0 ]; then _fail=1; echo please not run as root; fi
if [ $_fail -eq 1 ]; then exit; fi

helper_url=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main

./curl -s $helper_url/api.sh|./bash -s
