#!/bin/bash
set -e

# --- Defaults from environment or fallback ---
ENABLE_NTP=${ENABLE_NTP:-true}
ENABLE_GPS=${ENABLE_GPS:-false}
ENABLE_RTC=${ENABLE_RTC:-false}
NTP_SERVERS=${NTP_SERVERS:-"0.pool.ntp.org 1.pool.ntp.org"}
NTP_PRIORITY=${NTP_PRIORITY:-1}
GPS_PRIORITY=${GPS_PRIORITY:-2}
RTC_PRIORITY=${RTC_PRIORITY:-3}
GPS_DEVICE=${GPS_DEVICE:-/dev/ttyUSB0}
ENABLE_PPS=${ENABLE_PPS:-false}
PPS_DEVICE=${PPS_DEVICE:-/dev/pps0}
ENABLE_RTC_UPDATE_FROM_NTP=${ENABLE_RTC_UPDATE_FROM_NTP:-true}
ENABLE_RTC_UPDATE_FROM_GPS=${ENABLE_RTC_UPDATE_FROM_GPS:-true}
RTC_DEVICE=${RTC_DEVICE:-/dev/rtc0}
RTC_UPDATE_INTERVAL=${RTC_UPDATE_INTERVAL:-3600}
RTC_UPDATE_MIN_FIX_TIME=${RTC_UPDATE_MIN_FIX_TIME:-600}
RTC_UPDATE_MAX_DIFF=${RTC_UPDATE_MAX_DIFF:-20}
GPSD_LISTEN_NETWORK=${GPSD_LISTEN_NETWORK:-false}

# --- Compose NTP block ---
if [[ "$ENABLE_NTP" == "true" ]]; then
  NTP_BLOCK=""
  for NTP in $NTP_SERVERS; do
    NTP_BLOCK="${NTP_BLOCK}server $NTP iburst\n"
  done
  NTP_BLOCK="${NTP_BLOCK}# NTP priority: $NTP_PRIORITY\nntp_sourcedir /var/run/chrony"
else
  NTP_BLOCK="# NTP disabled"
fi

# --- Compose GPS block ---
if [[ "$ENABLE_GPS" == "true" ]]; then
  GPS_BLOCK="refclock SHM 0 poll 3 refid GPS # GPS priority: $GPS_PRIORITY"
  if [[ "$ENABLE_PPS" == "true" ]]; then
    GPS_BLOCK="$GPS_BLOCK\nrefclock PPS $PPS_DEVICE refid PPS lock GPS"
  fi
else
  GPS_BLOCK="# GPS disabled"
fi

# --- Compose RTC block ---
if [[ "$ENABLE_RTC" == "true" ]]; then
  RTC_BLOCK="refclock RTC $RTC_DEVICE refid RTC # RTC priority: $RTC_PRIORITY"
else
  RTC_BLOCK="# RTC disabled"
fi

# --- Debug output for troubleshooting ---
echo "--- Generated chrony.conf blocks ---"
echo -e "NTP_BLOCK:\n$NTP_BLOCK"
echo -e "GPS_BLOCK:\n$GPS_BLOCK"
echo -e "RTC_BLOCK:\n$RTC_BLOCK"
echo "------------------------------------"

# --- Generate chrony.conf ---
cat /chrony.conf.template \
  | sed "s|{{NTP_BLOCK}}|$NTP_BLOCK|" \
  | sed "s|{{GPS_BLOCK}}|$GPS_BLOCK|" \
  | sed "s|{{RTC_BLOCK}}|$RTC_BLOCK|" \
  > /etc/chrony/chrony.conf

# --- Start gpsd if enabled ---
if [[ "$ENABLE_GPS" == "true" ]]; then
  if [[ "$GPSD_LISTEN_NETWORK" == "true" ]]; then
    gpsd -n -G $GPS_DEVICE &
  else
    gpsd -n $GPS_DEVICE &
  fi
fi

# --- Start RTC updater if interval is enabled ---
if [[ "$RTC_UPDATE_INTERVAL" != "0" ]]; then
  /rtc-updater.sh &
fi

# --- Start chronyd in foreground ---
exec chronyd -d -f /etc/chrony/chrony.conf
