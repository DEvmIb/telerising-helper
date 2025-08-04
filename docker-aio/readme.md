# Telerising AIO Image

* Telerising
* EasyEPG
* Health Check

## ENV Variables

| Key                 | Value | Default | Optional | Description                           |
|---------------------|-------|---------|----------|---------------------------------------|
| TZ                  | any   |         | Y        | example: Europe/Berlin                |
| TR_VERSION          | ver   |         | Y        | force telerising version              |
| TR_PROVIDERS        | path  |         | Y        | path to own providers.json            |
| TR_DISABLE          | any   |         | Y        | if set, telerising is disabled        |
| EPG_DISABLE         | any   |         | Y        | if set, easyepg is disabled           |
| HEALTH_DISABLE      | any   |         | Y        | if set, healthcheck is disabled       |
| TRUPDATE            | Y     |         | Y        | Update Telerising on Docker restart   |
| HEALTH_INT          | num   | 300     | Y        | healthcheck interval, seconds         |       
| HEALTH_HOOK         | URL   |         | Y        | Post HEALTH Status to this URL        |
| HEALTH_HOOK_TYPE    | J/T   | J       | Y        | send json or text message             |
| HEALTH_MQTT_HOST    | HOST  |         | Y        | mqtt hostname                         |
| HEALTH_MQTT_PORT    | PORT  | 1883    | Y        | optional, mqqt port                   |
| HEALTH_MQTT_TOPIC   | TOPIC |         | Y        | send to this topic                    |
| HEALTH_MQTT_TYPE    | J/T   | J       | Y        | send json or text message             |
| HEALTH_MATRIX_URL   | URL   |         | Y        | matrix server url                     |
| HEALTH_MATRIX_ROOM  | ID    |         | Y        | matrix room send message to           |
| HEALTH_MATRIX_TOKEN | TXT   |         | Y        | you matrix token                      |
|                     |       |         |          | sends T only                          |
| HEALTH_KODI_URL     | URL   |         | Y        | only T type is send, without /jsonrpc |
| HEALTH_INFLUX_URL   | URL   |         | Y        | http://influx/api/v2/write            |
| HEALTH_INFLUX_BUCK  | TXT   |         | Y        | bucket name                           |
| HEALTH_INFLUX_ORG   | TXT   |         | Y        | organization name                     |
| HEALTH_INFLUX_TOKEN | TXT   |         | Y        | user token                            |
|                     |       |         |          | 0=ERR, 1=UNK, 2=OK                    |
| HEALTH_SMTP_HOST    | TXT   |         | Y        | mail server address                   |
| HEALTH_SMTP_PORT    | TXT   | 25      | Y        | mail server port                      |
| HEALTH_SMTP_FROM    | TXT   |         | Y        | from e.g. healtcheck@domain.com       |
| HEALTH_SMTP_FROM_N  | TXT   | check   | Y        | from name                             |
| HEALTH_SMTP_TO      | TXT   |         | Y        | to e.g. tr@domain.com                 |
|                     |       |         |          | send T only, no TLS                   |
| HEALTH_TG_TOKEN     | TXT   |         | Y        | telegram bot token, T only            |
| HEALTH_TG_TARGET    | TXT   |         | Y        | target id of user or chat             |
| http_proxy          | URL   |         | Y        | useful if you want to use telerising  |
| https_proxy         | URL   |         | Y        | his new proxy feature and route all   |
|                     |       |         |          | traffic through a proxy server        |

## Volumes

| Volume      | Description        |
|-------------|--------------------|
| /telerising | telerising storage |
| /easyepg    | easyepg storage    |

## Ports

| Port | Description        |
|------|--------------------|
| 3000 | json status output |
| 3001 | html status output |
| 4000 | easyepg port       |
| 5000 | telerising port    |

## Examples

### Json Output
```
curl -s http://telerising:3000|jq
```

```
{
  "code": 0,
  "msg": "health check working",
  "telerising": {
    "state": "down"
  },
  "easyepg": {
    "state": "up",
    "since": "1752657657",
    "since_human": "Wed Jul 16 11:20:57 CEST 2025"
  },
  "y3o": {
    "state": "ok",
    "name": "yallo.tv",
    "since": "1752678634",
    "since_human": "Wed Jul 16 17:10:34 CEST 2025"
  },
  "zc2": {
    "state": "ok",
    "name": "Zattoo CH (Web/Mobile)",
    "since": "1752678634",
    "since_human": "Wed Jul 16 17:10:34 CEST 2025"
  },
  "zd2": {
    "state": "fail",
    "name": "Zattoo DE (Web/Mobile)",
    "since": "1752678634",
    "since_human": "Wed Jul 16 17:10:34 CEST 2025"
  },
  "time": "1752682253",
  "time_human": "Wed Jul 16 18:10:53 CEST 2025"
}
```
### Push
* telerising, easyepg status
```
{"health":"ERROR","name":"easyepg","id":"easyepg"}
```
```
{"health":"OK","name":"telerising","id":"telerising"}
```
```
telerising down: on host telerising
```
```
easyepg up: on host telerising
```
* Provider
```
{"health":"ERROR","name":"Zattoo CH","id":"zch","msg":"wrong country"}
```
```
{"health":"OK","name":"Zattoo CH","id":"zch","msg":""}
```
```
telerising error: on host telerising id: zch service: Zattoo status: ERROR message: login failed
```
```
telerising ok: on host telerising id: zch service: Zattoo status: OK message:
```
### Web Status
```
http://telerising:3001
```
![what](telerising-status-check.png)
