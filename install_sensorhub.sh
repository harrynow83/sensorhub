#!/bin/bash
set -e

echo "======================================"
echo " Sensor Hub for Klipper"
echo " Instalador automático"
echo "======================================"

# No ejecutar como root
if [ "$EUID" -eq 0 ]; then
  echo "❌ No ejecutes este script como root"
  exit 1
fi

echo "🔍 Buscando Sensor Hub..."

PORT=$(ls /dev/serial/by-id/*CP2102* /dev/serial/by-id/*CH340* /dev/serial/by-id/*UART* 2>/dev/null | head -n 1)

if [ -z "$PORT" ]; then
  echo "❌ No se encontró el Sensor Hub"
  echo "➡️ Conéctalo por USB e inténtalo de nuevo"
  exit 1
fi

echo "✅ Sensor Hub encontrado:"
echo "   $PORT"

echo "📦 Instalando dependencias..."
sudo apt update
sudo apt install -y python3-serial

mkdir -p ~/sensorhub

echo "🧠 Instalando bridge..."
cat > ~/sensorhub/sensorhub_bridge.py << EOF
import serial
import subprocess
import time

SERIAL_PORT = "$PORT"
BAUD = 115200

def open_serial():
    while True:
        try:
            ser = serial.Serial(
                SERIAL_PORT,
                BAUD,
                timeout=1,
                exclusive=True
            )
            ser.reset_input_buffer()
            print("Sensor Hub conectado")
            return ser
        except Exception as e:
            print("Esperando Sensor Hub...", e)
            time.sleep(2)

ser = open_serial()

while True:
    try:
        line = ser.readline()
        if not line:
            continue

        line = line.decode(errors="ignore").strip()

        if not line.startswith("EVENT"):
            continue

        print("SENSOR:", line)

        subprocess.run(
            ["bash", "-c", "echo 'PAUSE' > /tmp/sensorhub_cmd"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

    except serial.SerialException:
        try:
            ser.close()
        except:
            pass
        time.sleep(1)
        ser = open_serial()
EOF

chmod +x ~/sensorhub/sensorhub_bridge.py

echo "⚙️ Creando servicio systemd..."
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

sudo systemctl daemon-reload
sudo systemctl enable sensorhub
sudo systemctl restart sensorhub

CFG=~/printer.cfg

if ! grep -q "SENSOR HUB" "$CFG"; then
  echo "🧩 Añadiendo macros a printer.cfg"
  cat >> "$CFG" << 'EOF'

# ===== SENSOR HUB =====
[gcode_shell_command SENSORHUB_CMD]
command: bash -c "cat /tmp/sensorhub_cmd"
timeout: 2
verbose: False

[gcode_macro SENSORHUB_PAUSE]
gcode:
    PAUSE
# ======================
EOF
fi

echo "======================================"
echo "✅ INSTALACIÓN COMPLETADA"
echo ""
echo "➡️ Reinicia Klipper"
echo "➡️ Inicia una impresión y prueba quitando el filamento"
echo "======================================"
