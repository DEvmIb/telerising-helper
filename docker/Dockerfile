FROM alpine:3.22.0 AS build

LABEL maintainer="Ad0lar <ad0lar.pasture129@passmail.net>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="docker.telerising-alpine"

COPY start.sh /usr/local/sbin/entrypoint
COPY qemu-* /usr/bin

RUN chmod +x /usr/local/sbin/entrypoint

ENTRYPOINT [ "/usr/local/sbin/entrypoint" ]

VOLUME /telerising

EXPOSE 5000

RUN rm -rf /usr/bin/qemu-*
