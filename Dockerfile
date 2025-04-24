FROM alpine:3.19

RUN apk add --no-cache chrony gpsd gpsd-clients tzdata bash

COPY entrypoint.sh /entrypoint.sh
COPY chrony.conf.template /chrony.conf.template
COPY rtc-updater.sh /rtc-updater.sh

RUN chmod +x /entrypoint.sh /rtc-updater.sh

EXPOSE 123/udp
EXPOSE 2947/tcp

ENTRYPOINT ["/entrypoint.sh"]