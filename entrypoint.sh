#!/bin/bash
set -e

# Utility: Robust bool parser for env vars
is_enabled() {
  case "${1,,}" in
    true|1|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Entrypoint started at $(date)"
echo "ENABLE_NTP: [$ENABLE_NTP]"
echo "ENABLE_GPS: [$ENABLE_GPS]"
echo "ENABLE_PPS: [$ENABLE_PPS]"
echo "ENABLE_RTC: [$ENABLE_RTC]"
echo "NTP_SERVERS: [$NTP_SERVERS]"
echo "GPS_DEVICE: [$GPS_DEVICE]"
echo "RTC_DEVICE: [$RTC_DEVICE]"
# Defaults
ENABLE_NTP="${ENABLE_NTP:-true}"
ENABLE_GPS="${ENABLE_GPS:-false}"
ENABLE_PPS="${ENABLE_PPS:-false}"
ENABLE_RTC="${ENABLE_RTC:-false}"
NTP_SERVERS="${NTP_SERVERS:-0.pool.ntp.org 1.pool.ntp.org}"
NTP_PRIORITY="${NTP_PRIORITY:-1}"
GPS_PRIORITY="${GPS_PRIORITY:-2}"
RTC_PRIORITY="${RTC_PRIORITY:-3}"
GPS_DEVICE="${GPS_DEVICE:-/dev/ttyUSB0}"
RTC_DEVICE="${RTC_DEVICE:-/dev/rtc0}"
RTC_UPDATE_INTERVAL="${RTC_UPDATE_INTERVAL:-3600}"
GPSD_LISTEN_NETWORK="${GPSD_LISTEN_NETWORK:-false}"

# Compose NTP block
if is_enabled "$ENABLE_NTP"; then
#  NTP_BLOCK="log all\n"
  for NTP in $NTP_SERVERS; do
    NTP_BLOCK="${NTP_BLOCK}server $NTP iburst\n"
  done
  NTP_BLOCK="${NTP_BLOCK}# NTP priority: $NTP_PRIORITY"
else
  NTP_BLOCK="# NTP disabled"
fi

# Compose GPS block
if is_enabled "$ENABLE_GPS"; then
#  GPS_BLOCK="refclock SHM 0 refid GPS"
  GPS_BLOCK="$GPS_BLOCK_ROLL_1"
  GPS_BLOCK="$GPS_BLOCK\n$GPS_BLOCK_ROLL_2"
  if is_enabled "$ENABLE_PPS"; then
    GPS_BLOCK="$GPS_BLOCK\n$GPS_PPS_ROLL_1"
    GPS_BLOCK="$GPS_BLOCK\n$GPS_PPS_ROLL_2"
  fi
else
  GPS_BLOCK="# GPS disabled"
fi

# Compose RTC block
if is_enabled "$ENABLE_RTC"; then
  RTC_BLOCK="#RTC_BLOCK"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_1"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_2"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_3"
else
  RTC_BLOCK="# RTC disabled"
fi

# Compose RTC block
if is_enabled "$ENABLE_RTC"; then
  RTC_BLOCK="#RTC_BLOCK"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_1"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_2"
  RTC_BLOCK="$RTC_BLOCK\n$RTC_ROLL_3"
else
  RTC_BLOCK="# RTC disabled"
fi

# Debug: Show blocks
echo -e "NTP_BLOCK:\n$NTP_BLOCK"
echo -e "GPS_BLOCK:\n$GPS_BLOCK"
echo -e "RTC_BLOCK:\n$RTC_BLOCK"

# Generate chrony.conf
sed \
  -e "s|{{NTP_BLOCK}}|$NTP_BLOCK|" \
  -e "s|{{GPS_BLOCK}}|$GPS_BLOCK|" \
  -e "s|{{RTC_BLOCK}}|$RTC_BLOCK|" \
  /chrony.conf.template > /etc/chrony/chrony.conf

echo "----- /etc/chrony/chrony.conf (line numbered) -----"
cat -n /etc/chrony/chrony.conf
echo "---------------------------------------------------"

# Start gpsd if enabled
if is_enabled "$ENABLE_GPS"; then
  if is_enabled "$GPSD_LISTEN_NETWORK"; then
    gpsd -n -G $GPS_DEVICE &
  else
    gpsd -n $GPS_DEVICE &
  fi
fi

sleep 5

# Compose RTC block
#if is_enabled "$ENABLE_RTC"; then
# Links RTC to shared memory
#   ln -s /dev/rtc0 /dev/shm/1
#   chmod 644 /dev/shm/1
#   chown root:chrony /dev/shm/1
#else

#fi

# Start RTC updater if enabled
if is_enabled "$ENABLE_RTC" && [[ "$RTC_UPDATE_INTERVAL" != "0" ]]; then
  /rtc-updater.sh &
fi

# Start chronyd in foreground
exec chronyd -d -f /etc/chrony/chrony.conf
