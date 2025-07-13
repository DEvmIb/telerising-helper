#!/bin/sh
apk add --no-cache bash
wget -qO - https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main/api.sh|bash -s -- /telerising
