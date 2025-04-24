FROM alpine:3.19

RUN apk add --no-cache chrony gpsd gpsd-clients

COPY entrypoint.sh /entrypoint.sh
COPY chrony.conf.template /chrony.conf.template

RUN chmod +x /entrypoint.sh

EXPOSE 123/udp
EXPOSE 2947/tcp

ENTRYPOINT ["/entrypoint.sh"]