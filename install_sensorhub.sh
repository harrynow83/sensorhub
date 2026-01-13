#!/bin/bash

set -e

echo "======================================"
echo " Sensor Hub - Instalador automático"
echo "======================================"

# 1. Comprobar usuario
if [ "$EUID" -eq 0 ]; then
  echo "❌ No ejecutes como root"
  exit 1
fi

# 2. Detectar ESP32
echo "🔍 Buscando Sensor Hub..."
PORT=$(ls /dev/serial/by-id/*CP2102* /dev/serial/by-id/*UART* 2>/dev/null | head -n 1)

if [ -z "$PORT" ]; then
  echo "❌ No se encontró el Sensor Hub."
  echo "➡️ Conéctalo por USB e inténtalo de nuevo."
  exit 1
fi

echo "✅ Sensor Hub encontrado en:"
echo "   $PORT"

# 3. Instalar dependencias
echo "📦 Instalando dependencias..."
sudo apt update
sudo apt install -y python3-serial

# 4. Crear directorio
mkdir -p ~/sensorhub

# 5. Crear bridge Python
echo "🧠 Instalando bridge..."
cat > ~/sensorhub/sensorhub_bridge.py << EOF
import serial
import subprocess

SERIAL = "$PORT"
BAUD = 115200

ser = serial.Serial(SERIAL, BAUD, timeout=1)

while True:
    line = ser.readline().decode(errors="ignore").strip()
    if not line:
        continue

    if "EVENT" in line:
        subprocess.run(["bash", "-c",
            "echo 'PAUSE' > /tmp/sensorhub_cmd"])
EOF

chmod +x ~/sensorhub/sensorhub_bridge.py

# 6. Crear servicio systemd
echo "⚙️ Creando servicio..."
sudo tee /etc/systemd/system/sensorhub.service > /dev/null << EOF
[Unit]
Description=Sensor Hub Bridge
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/$USER/sensorhub/sensorhub_bridge.py
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# 7. Activar servicio
sudo systemctl daemon-reload
sudo systemctl enable sensorhub
sudo systemctl restart sensorhub

# 8. Añadir macro Klipper
CFG=~/printer.cfg

if ! grep -q "SENSORHUB_PAUSE" "$CFG"; then
  echo "🧩 Añadiendo macros a printer.cfg"
  cat >> "$CFG" << 'EOF'

# === SENSOR HUB ===
[gcode_shell_command SENSORHUB_CMD]
command: bash -c "cat /tmp/sensorhub_cmd"
timeout: 2
verbose: False

[gcode_macro SENSORHUB_PAUSE]
gcode:
    PAUSE
# ==================
EOF
else
  echo "ℹ️ Macros ya existentes"
fi

# 9. Final
echo "======================================"
echo "✅ INSTALACIÓN COMPLETADA"
echo ""
echo "➡️ Reinicia Klipper"
echo "➡️ Prueba quitando el filamento"
echo "➡️ La impresora debe pausarse"
echo "======================================"

