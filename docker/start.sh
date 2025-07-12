#!/bin/sh
apk add --no-cache curl bash
curl -s https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main/api.sh|bash -s -- /telerising
