# Lightweight NTP Server with GPSD (chrony + gpsd) in Docker

This project provides a lightweight Docker image for an NTP server that uses GPS data via gpsd, with optional PPS support and the ability to expose gpsd to custom applications.

## Features

- **Chrony** as the NTP server
- **gpsd** to provide GPS data (and optionally PPS)
- Configurable GPS device path via environment variable
- Optional PPS support (for higher precision)
- Optionally expose gpsd’s TCP port for use by custom apps
- Easy deployment with Docker Compose

## Usage

### 1. Build the Image

```sh
docker-compose build
```

### 2. Run with Docker Compose

Edit `docker-compose.yml` to match your hardware (GPS device path, PPS usage, etc).

```sh
docker-compose up -d
```

### 3. Environment Variables

- `GPS_DEVICE` – Path to your GPS device (default: `/dev/ttyUSB0`)
- `ENABLE_PPS` – Set to `true` to enable PPS (default: `false`)
- `GPSD_LISTEN_NETWORK` – Set to `true` to allow gpsd network access on TCP port 2947 (default: `false`)

### 4. Device Mapping

In `docker-compose.yml`, ensure you map your host’s GPS device into the container, e.g.:

```yaml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
  # - "/dev/pps0:/dev/pps0"  # Uncomment if you're using PPS
```

### 5. Exposing gpsd for Custom Apps

- By default, gpsd is *not* exposed to the network.
- Set `GPSD_LISTEN_NETWORK=true` to make gpsd listen on all interfaces (port 2947).  
  Your apps can then connect to `tcp://<host_ip>:2947`.

**Security Note:** Exposing gpsd to the network may leak location data. Only enable this on trusted networks.

### 6. Ports

- NTP (UDP 123) is available (host networking is used for best performance).
- gpsd (TCP 2947) is optionally available if `GPSD_LISTEN_NETWORK` is enabled.

## Example: Run with PPS and Networked gpsd

```yaml
environment:
  - GPS_DEVICE=/dev/ttyUSB0
  - ENABLE_PPS=true
  - GPSD_LISTEN_NETWORK=true
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
  - "/dev/pps0:/dev/pps0"
```

## File Structure

- `Dockerfile` – Builds the image with chrony, gpsd, and entrypoint script
- `entrypoint.sh` – Handles env vars, starts gpsd and chrony
- `chrony.conf.template` – Templated chrony config
- `docker-compose.yml` – Example deployment configuration

## License

MIT

---

**Questions or improvements?**  
Open an issue or PR!