# Sensor Hub for Klipper

Sensor inteligente de filamento para impresoras 3D con Klipper.
Detecta automáticamente:
- Fin de filamento
- Atascos (clog)
- Slip del extrusor

Cuando ocurre un problema, la impresión se **pausa automáticamente**.

---

## ✅ Requisitos

- Klipper funcionando (Mainsail / Fluidd / OctoKlipper)
- Raspberry Pi o similar
- Sensor Hub conectado por USB

---
## luces de estado

| Color       | Significado               |
| ----------- | ------------------------- |
| 🔵 Azul     | Arrancando                |
| 🟢 Verde    | Todo correcto             |
| 🟡 Amarillo | Advertencia               |
| 🔴 Rojo     | Error (impresión pausada) |


## ❓ Solución de problemas

El sensor no pausa la impresión
Comprueba que el servicio está activo:

sudo systemctl status sensorhub


Debe decir:
Active: active (running)


## Ver mensajes del sensor
journalctl -u sensorhub -f

# 🔧 Desinstalar
sudo systemctl disable sensorhub
sudo systemctl stop sensorhub
rm -rf ~/sensorhub
sudo rm /etc/systemd/system/sensorhub.service

---

# macros obligatorios para tu printer.cfg

[gcode_macro SENSORHUB_PAUSE]
gcode:
    PAUSE

## 🚀 Instalación (1 SOLO COMANDO)

Conecta el Sensor Hub por USB y ejecuta:

```bash
curl -sSL https://raw.githubusercontent.com/harrynow83/sensorhub/main/install_sensorhub.sh | bash

