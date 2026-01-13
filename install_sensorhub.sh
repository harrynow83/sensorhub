#!/bin/bash
set -e

echo "======================================"
echo " Sensor Hub for Klipper"
echo " Instalador interactivo"
echo "======================================"

if [ "$EUID" -eq 0 ]; then
  echo "❌ No ejecutes este script como root"
  exit 1
fi

# Detectar puerto USB del sensor
echo "🔍 Buscando Sensor Hub..."
PORT=$(ls /dev/serial/by-id/*CP2102* /dev/serial/by-id/*CH340* /dev/serial/by-id/*UART* 2>/dev/null | head -n 1)

if [ -z "$PORT" ]; then
  echo "❌ No se encontró el Sensor Hub por USB"
  exit 1
fi

echo "✅ Sensor Hub encontrado:"
echo "   $PORT"
echo ""

# Detectar instancias Klipper
echo "🔍 Detectando impresoras Klipper..."
PRINTERS=($(ls -d ~/printer_*_data 2>/dev/null))

if [ ${#PRINTERS[@]} -eq 0 ]; then
  echo "❌ No se encontraron instancias Klipper"
  exit 1
fi

echo ""
echo "Impresoras detectadas:"
i=1
for p in "${PRINTERS[@]}"; do
  echo " [$i] $(basename "$p")"
  ((i++))
done

echo ""
read -p "👉 Selecciona el número de impresora: " SEL < /dev/tty

IDX=$((SEL-1))
TARGET="${PRINTERS[$IDX]}"

if [ -z "$TARGET" ]; then
  echo "❌ Selección inválida"
  exit 1
fi

echo ""
echo "✅ Instalando Sensor Hub en:"
echo "   $(basename "$TARGET")"
echo ""

# Instalar dependencias
echo "📦 Instalando dependencias..."
sudo apt update
sudo apt install -y python3-serial socat

# Crear carpeta sensorhub
mkdir -p "$TARGET/sensorhub"

# Crear bridge Python
echo "🧠 Creando bridge..."
cat > "$TARGET/sensorhub/sensorhub_bridge.py" << EOF
import serial
import subprocess
import time

SERIAL_PORT = "$PORT"
BAUD = 115200
SOCKET = "$TARGET/comms/klippy.sock"

def open_serial():
    while True:
        try:
            ser = serial.Serial(SERIAL_PORT, BAUD, timeout=1, exclusive=True)
            ser.reset_input_buffer()
            print("Sensor Hub conectado")
            return ser
        except Exception:
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

        subprocess.run([
            "bash", "-c",
            f"echo PAUSE | socat - UNIX-CONNECT:{SOCKET}"
        ])

    except Exception:
        try:
            ser.close()
        except:
            pass
        time.sleep(1)
        ser = open_serial()
EOF

chmod +x "$TARGET/sensorhub/sensorhub_bridge.py"

# Crear servicio systemd
SERVICE="sensorhub_$(basename "$TARGET")"

echo "⚙️ Creando servicio systemd: $SERVICE"

sudo tee "/etc/systemd/system/$SERVICE.service" > /dev/null << EOF
[Unit]
Description=Sensor Hub for $(basename "$TARGET")
After=network.target

[Service]
ExecStart=/usr/bin/python3 $TARGET/sensorhub/sensorhub_bridge.py
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE"
sudo systemctl restart "$SERVICE"

echo ""
echo "======================================"
echo "✅ INSTALACIÓN COMPLETADA"
echo ""
echo "➡️ Impresora: $(basename "$TARGET")"
echo "➡️ Servicio: $SERVICE"
echo ""
echo "➡️ Reinicia Klipper de esa impresora"
echo "➡️ Inicia una impresión y prueba quitando el filamento"
echo "======================================"
