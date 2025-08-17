# QR Menu

A Rails API application for restaurant menu management with QR code generation capabilities.

## Features

- Restaurant and menu management
- QR code generation for menus
- **WiFi QR code generation** - Generate QR codes for WiFi network connections

## WiFi QR Endpoint

Generate QR codes for WiFi network credentials:

```bash
# Basic usage
GET /qr/wifi?ssid=MyWifi&auth=WPA&password=secret123

# Open network
GET /qr/wifi?ssid=FreeWifi&auth=nopass

# SVG format
GET /qr/wifi?ssid=MyWifi&auth=WPA&password=secret&format=svg

# Hidden network
GET /qr/wifi?ssid=HiddenNet&auth=WPA&password=secret&hidden=true
```

See [WiFi QR Endpoint Documentation](./docs/wifi_qr_endpoint.md) for detailed usage.

## Setup

* Ruby version: 3.2.3

* System dependencies
  - PostgreSQL
  - ImageMagick (for image processing)

* Configuration
  - Set up environment variables for Auth0, AWS S3, and database

* Database creation
  ```bash
  rails db:create
  rails db:migrate
  ```

* How to run the test suite
  ```bash
  bundle exec rspec
  ```

* Deployment instructions
  - Configure environment variables
  - Run database migrations
  - Deploy to your hosting platform
