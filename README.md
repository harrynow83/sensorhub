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

## 🚀 Instalación (1 SOLO COMANDO)

Conecta el Sensor Hub por USB y ejecuta:

```bash
curl -sSL https://raw.githubusercontent.com/harrynow83/sensorhub/main/install_sensorhub.sh | bash
