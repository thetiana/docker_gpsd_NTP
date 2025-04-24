# Robust Dockerized NTP Server with GPS/GPSD/RTC Redundancy

This project provides a highly configurable NTP server in a Docker container using [chrony](https://chrony.tuxfamily.org/), [gpsd](https://gpsd.io/), and optional RTC hardware, with robust redundancy logic.

## Features

- Enables/disables NTP, GPS, and RTC sources via environment variables
- Custom NTP server list and priorities
- PPS and RTC support with device mapping
- GPSD network access optional
- RTC update logic: 
  - Update RTC if both NTP and GPS agree (within threshold)
  - Configurable: minimum GPS fix age, allowed time difference, update interval, update source
  - Never updates RTC if GPS could be spoofed or time jump is suspicious

## Usage

### 1. Build the Image

```sh
docker build -t ntp-gpsd .
```

### 2. Configure and Run

Edit `docker-compose.yml` to match your hardware and desired logic, then:

```sh
docker compose up -d
```

### 3. Environment Variables

| Variable                        | Default          | Description                                     |
|----------------------------------|------------------|-------------------------------------------------|
| ENABLE_NTP                      | true             | Enable/disable mainstream NTP                   |
| ENABLE_GPS                      | true             | Enable/disable GPSD source                      |
| ENABLE_RTC                      | false            | Enable/disable RTC source                       |
| NTP_SERVERS                     | pool.ntp.org...  | Space-separated NTP servers                     |
| NTP_PRIORITY, GPS_PRIORITY, RTC_PRIORITY | 1,2,3   | Priority for sources (not strictly enforced)     |
| GPS_DEVICE                      | /dev/ttyUSB0     | GPS device path                                 |
| ENABLE_PPS                      | false            | Enable PPS                                      |
| PPS_DEVICE                      | /dev/pps0        | PPS device path                                 |
| RTC_DEVICE                      | /dev/rtc0        | RTC device path                                 |
| ENABLE_RTC_UPDATE_FROM_NTP      | true             | Allow RTC updates from NTP                      |
| ENABLE_RTC_UPDATE_FROM_GPS      | true             | Allow RTC updates from GPS                      |
| RTC_UPDATE_INTERVAL             | 3600             | RTC update interval in seconds, 0=disabled      |
| RTC_UPDATE_MIN_FIX_TIME         | 600              | Min GPS fix age (s) for RTC update              |
| RTC_UPDATE_MAX_DIFF             | 20               | Max allowed diff (s) between RTC and source     |
| GPSD_LISTEN_NETWORK             | false            | Expose gpsd on TCP 2947 for network access      |

### 4. Devices

Map devices as needed:
```yaml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
  - "/dev/rtc0:/dev/rtc0"
  # - "/dev/pps0:/dev/pps0"
```

### 5. Security

If you set `GPSD_LISTEN_NETWORK=true`, gpsd will accept connections on the network. Only do this on trusted networks!

### 6. Troubleshooting

- Ensure your host provides the mapped devices and you have correct permissions.
- For best results, run on Linux with `network_mode: host` and necessary `cap_add`.

---

## Questions or improvements?

Open an issue or PR!