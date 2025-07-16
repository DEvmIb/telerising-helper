FROM alpine:3.22.0 AS build

LABEL maintainer="Ad0lar <ad0lar.pasture129@passmail.net>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="docker.telerising-aio"

COPY start.sh /usr/local/bin/start.sh
COPY health-check.sh /usr/local/bin/health-check.sh
COPY health-socat.sh /usr/local/bin/health-socat.sh
COPY health-socat-html.sh /usr/local/bin/health-socat-html.sh

COPY qemu-* /usr/bin

RUN chmod +x /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-socat.sh
RUN chmod +x /usr/local/bin/health-socat-html.sh

ENTRYPOINT [ "/usr/local/bin/start.sh" ]

VOLUME /easyepg
VOLUME /telerising

EXPOSE 3000
EXPOSE 3001
EXPOSE 4000
EXPOSE 5000

RUN rm -f /usr/bin/qemu-*
