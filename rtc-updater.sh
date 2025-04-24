#!/bin/bash

RTC_DEVICE=${RTC_DEVICE:-/dev/rtc0}
RTC_UPDATE_INTERVAL=${RTC_UPDATE_INTERVAL:-3600}
ENABLE_RTC_UPDATE_FROM_NTP=${ENABLE_RTC_UPDATE_FROM_NTP:-true}
ENABLE_RTC_UPDATE_FROM_GPS=${ENABLE_RTC_UPDATE_FROM_GPS:-true}
RTC_UPDATE_MIN_FIX_TIME=${RTC_UPDATE_MIN_FIX_TIME:-600}
RTC_UPDATE_MAX_DIFF=${RTC_UPDATE_MAX_DIFF:-20}

# Helper to get system time as seconds since epoch
sys_time() { date +%s; }

# Helper to get RTC time as seconds since epoch
rtc_time() {
  hwclock --get --device $RTC_DEVICE --utc 2>/dev/null | awk '{print $4" "$5" "$6" "$7" "$8}' | xargs -I{} date -d "{}" +%s
}

# Helper to check if chrony is synced to NTP
chrony_ntp_synced() {
  chronyc tracking 2>/dev/null | grep -qi "Leap status.*Normal"
}

# Helper to check if chrony is synced to GPS
chrony_gps_synced() {
  chronyc sources 2>/dev/null | grep -qE '\^\*.*SHM'
}

# Helper to get GPS fix duration (seconds)
gps_fix_duration() {
  gpspipe -w -n 10 2>/dev/null | grep TPV | grep -m1 '"mode":3' | awk -F'"' '/time/ {print $4}' | head -n1 | xargs -I{} date -d "{}" +%s
}

while sleep "$RTC_UPDATE_INTERVAL"; do
  sys_sec=$(sys_time)
  rtc_sec=$(rtc_time)
  [ -z "$rtc_sec" ] && continue
  diff=$((sys_sec-rtc_sec))
  diff_abs=${diff#-}

  # Prefer NTP as sync source
  if [[ "$ENABLE_RTC_UPDATE_FROM_NTP" == "true" ]] && chrony_ntp_synced; then
    if [[ "$diff_abs" -le "$RTC_UPDATE_MAX_DIFF" ]]; then
      hwclock --systohc --utc --device $RTC_DEVICE
      echo "RTC updated from NTP (sys/rtc diff $diff_abs sec)"
    fi
  # If only GPS is available and allowed
  elif [[ "$ENABLE_RTC_UPDATE_FROM_GPS" == "true" ]] && chrony_gps_synced; then
    # Wait for GPS fix duration
    gpsfix=$(gps_fix_duration)
    now=$(date +%s)
    fixage=$((now-gpsfix))
    if [[ "$fixage" -ge "$RTC_UPDATE_MIN_FIX_TIME" && "$diff_abs" -le "$RTC_UPDATE_MAX_DIFF" ]]; then
      hwclock --systohc --utc --device $RTC_DEVICE
      echo "RTC updated from GPS (sys/rtc diff $diff_abs sec, fix age $fixage sec)"
    fi
  fi
done