# WiFi QR Endpoint Documentation

## Overview
The WiFi QR endpoint generates QR codes for WiFi network connections in both PNG and SVG formats.

## Endpoint
```
GET /qr/wifi
```

## Parameters

| Parameter | Type    | Required | Default | Description |
|-----------|---------|----------|---------|-------------|
| `ssid`    | string  | Yes      | -       | WiFi network name |
| `auth`    | string  | No       | WPA     | Authentication type: `WPA`, `WEP`, or `nopass` |
| `password`| string  | No*      | -       | Network password (*required for WPA/WEP) |
| `hidden`  | boolean | No       | false   | Whether the network is hidden |
| `format`  | string  | No       | png     | Output format: `png` or `svg` |

## Authentication Types
- `WPA`, `WPA2`, `WPA3` → normalized to `WPA`
- `WEP` → stays as `WEP`
- `nopass` → for open networks

## Usage Examples

### Basic WPA network (PNG)
```bash
curl "http://localhost:3000/qr/wifi?ssid=Office&auth=WPA&password=secret123"
```

### Open network (no password)
```bash
curl "http://localhost:3000/qr/wifi?ssid=FreeWifi&auth=nopass"
```

### Hidden network with SVG output
```bash
curl "http://localhost:3000/qr/wifi?ssid=HiddenNet&auth=WPA&password=secret&hidden=true&format=svg"
```

### WEP network
```bash
curl "http://localhost:3000/qr/wifi?ssid=OldRouter&auth=WEP&password=key123"
```

## Response Types

### Success (PNG)
- Status: `200 OK`
- Content-Type: `image/png`
- Body: Binary PNG image data

### Success (SVG)
- Status: `200 OK`
- Content-Type: `image/svg+xml`
- Body: SVG markup

### Error Response
- Status: `400 Bad Request` or `500 Internal Server Error`
- Content-Type: `application/json`
- Body: `{"error": "error message"}`

## Error Cases
- Missing or empty SSID
- Missing password for WPA/WEP networks
- Invalid format (only `png` and `svg` supported)
- Invalid authentication type

## WiFi QR Payload Format
The generated QR codes contain a standardized WiFi payload:
```
WIFI:T:<auth>;S:<ssid>;P:<password>;H:<true|false>;;
```

Examples:
- `WIFI:T:WPA;S:Office;P:secret123;H:false;`
- `WIFI:T:nopass;S:FreeWifi;H:false;`
- `WIFI:T:WEP;S:Router;P:key;H:true;`

## Special Characters
Special characters in SSID and password are automatically escaped:
- `;` → `\;`
- `:` → `\:`
- `,` → `\,`
- `"` → `\"`
- `\` → `\\`

## Public Access
This endpoint is publicly accessible and does not require authentication.