#!/bin/sh
set -e

GPS_DEVICE=${GPS_DEVICE:-/dev/ttyUSB0}
ENABLE_PPS=${ENABLE_PPS:-false}
GPSD_LISTEN_NETWORK=${GPSD_LISTEN_NETWORK:-false}

# Build PPS block for chrony.conf
if [ "$ENABLE_PPS" = "true" ]; then
    PPS_BLOCK="refclock PPS /dev/pps0 refid PPS lock GPS"
else
    PPS_BLOCK="# PPS not enabled"
fi

sed \
    -e "s|{{PPS_BLOCK}}|$PPS_BLOCK|g" \
    /chrony.conf.template > /etc/chrony/chrony.conf

# Start gpsd with or without network listening
if [ "$GPSD_LISTEN_NETWORK" = "true" ]; then
    gpsd -n -G $GPS_DEVICE
else
    gpsd -n $GPS_DEVICE
fi

# Start chronyd
exec chronyd -d -f /etc/chrony/chrony.conf