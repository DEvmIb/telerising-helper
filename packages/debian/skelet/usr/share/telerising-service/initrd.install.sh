#!/bin/bash
cp /opt/telerising-service/initrd /etc/init.d/telerising-service
chmod 0755 /etc/init.d/telerising-service
update-rc.d telerising-service defaults
/etc/init.d/telerising-service start