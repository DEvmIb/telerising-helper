#!/bin/bash

echo docker login
docker login

rm -f qemu-5.2.0.balena4-arm.tar.gz
rm -f qemu-5.2.0.balena4-aarch64.tar.gz
rm -f qemu-arm-static
rm -f qemu-aarch64-static
rm -f manifest-tool

curl -LO https://github.com/balena-io/qemu/releases/download/v5.2.0%2Bbalena4/qemu-5.2.0.balena4-arm.tar.gz
if [ $? -ne 0 ]; then echo err dl qemu-5.2.0.balena4-arm.tar.gz; rm -f qemu-5.2.0.balena4-arm.tar.gz; exit 1; fi
curl -LO https://github.com/balena-io/qemu/releases/download/v5.2.0%2Bbalena4/qemu-5.2.0.balena4-aarch64.tar.gz
if [ $? -ne 0 ]; then echo err dl qemu-5.2.0.balena4-aarch64.tar.gz; rm -f qemu-5.2.0.balena4-aarch64.tar.gz; exit 1; fi


tar --strip-components=1 -zxf qemu-5.2.0.balena4-arm.tar.gz
if [ $? -ne 0 ]; then echo err tar qemu-5.2.0.balena4-aarch64.tar.gz; rm -f qemu-5.2.0.balena4-arm.tar.gz; rm -f qemu-arm-static; exit 1; fi

tar --strip-components=1 -zxf qemu-5.2.0.balena4-aarch64.tar.gz
if [ $? -ne 0 ]; then echo err tar qemu-5.2.0.balena4-aarch64.tar.gz; rm -f qemu-5.2.0.balena4-arm.tar.gz; rm -f qemu-aarch64-static; exit 1; fi

rm -f qemu-5.2.0.balena4-arm.tar.gz
rm -f qemu-5.2.0.balena4-aarch64.tar.gz

docker build -t ad0lar/telerising-aio:arm32v6 -f Dockerfile --platform="linux/arm/v6" .
if [ $? -ne 0 ]; then echo err build arm32v6; exit 1; fi

docker build -t ad0lar/telerising-aio:arm32v7 -f Dockerfile --platform="linux/arm/v7" .
if [ $? -ne 0 ]; then echo err build arm32v7; exit 1; fi

docker build -t ad0lar/telerising-aio:arm32v8 -f Dockerfile --platform="linux/arm/v8" .
if [ $? -ne 0 ]; then echo err build arm32v8; exit 1; fi

docker build -t ad0lar/telerising-aio:amd64 -f Dockerfile --platform="linux/amd64" .
if [ $? -ne 0 ]; then echo err build amd64; exit 1; fi

docker build -t ad0lar/telerising-aio:arm64 -f Dockerfile --platform="linux/arm64" .
if [ $? -ne 0 ]; then echo err build arm64; exit 1; fi

curl -Lo manifest-tool https://github.com/estesp/manifest-tool/releases/download/v0.9.0/manifest-tool-linux-amd64
if [ $? -ne 0 ]; then err dl manifest; rm -f manifest-tool; exit 1; fi
chmod +x manifest-tool

docker push ad0lar/telerising-aio:amd64
docker push ad0lar/telerising-aio:arm32v6
docker push ad0lar/telerising-aio:arm32v7
docker push ad0lar/telerising-aio:arm32v8
docker push ad0lar/telerising-aio:arm64

./manifest-tool push from-spec multi-arch-manifest.yaml
if [ $? -ne 0 ]; then err manifest; rm -f manifest-tool; exit 1; fi

#cleanup
rm -f qemu-arm-static
rm -f qemu-aarch64-static
rm -f manifest-tool
