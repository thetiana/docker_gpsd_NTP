#!/bin/bash
set -e

ENABLE_NTP=${ENABLE_NTP:-true}
ENABLE_GPS=${ENABLE_GPS:-false}
ENABLE_RTC=${ENABLE_RTC:-false}
NTP_SERVERS=${NTP_SERVERS:-"0.pool.ntp.org 1.pool.ntp.org"}
GPS_DEVICE=${GPS_DEVICE:-/dev/ttyUSB0}
ENABLE_PPS=${ENABLE_PPS:-false}
PPS_DEVICE=${PPS_DEVICE:-/dev/pps0}
RTC_DEVICE=${RTC_DEVICE:-/dev/rtc0}
GPSD_LISTEN_NETWORK=${GPSD_LISTEN_NETWORK:-false}

# NTP block
if [[ "$ENABLE_NTP" == "true" ]]; then
  NTP_BLOCK=$(echo "$NTP_SERVERS" | xargs -n1 | sed 's/^/server /;s/$/ iburst/' | tr '\n' '\\n')
else
  NTP_BLOCK="# NTP disabled"
fi

# GPS block
if [[ "$ENABLE_GPS" == "true" ]]; then
  GPS_BLOCK="refclock SHM 0 poll 3 refid GPS"
  if [[ "$ENABLE_PPS" == "true" ]]; then
    GPS_BLOCK="$GPS_BLOCK\nrefclock PPS $PPS_DEVICE refid PPS lock GPS"
  fi
else
  GPS_BLOCK="# GPS disabled"
fi

# RTC block
if [[ "$ENABLE_RTC" == "true" ]]; then
  RTC_BLOCK="refclock RTC $RTC_DEVICE refid RTC"
else
  RTC_BLOCK="# RTC disabled"
fi

# Generate chrony.conf (preserving comments for disabled blocks)
printf "%b" "$(cat /chrony.conf.template)" \
  | sed "s|{{NTP_BLOCK}}|$NTP_BLOCK|g" \
  | sed "s|{{GPS_BLOCK}}|$GPS_BLOCK|g" \
  | sed "s|{{RTC_BLOCK}}|$RTC_BLOCK|g" \
  > /etc/chrony/chrony.conf

if [[ "$ENABLE_GPS" == "true" ]]; then
  if [[ "$GPSD_LISTEN_NETWORK" == "true" ]]; then
    gpsd -n -G $GPS_DEVICE &
  else
    gpsd -n $GPS_DEVICE &
  fi
fi

exec chronyd -d -f /etc/chrony/chrony.conf
