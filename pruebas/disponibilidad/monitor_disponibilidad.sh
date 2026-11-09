#!/usr/bin/env bash
set -u
# Uso: bash monitor_disponibilidad.sh aurora "$AURORA_HOST" "$AURORA_USER" "$AURORA_PASS"
NOMBRE="${1:?Nombre del motor requerido}"
HOST="${2:?Endpoint requerido}"
USUARIO="${3:?Usuario requerido}"
CLAVE="${4:?Contraseña requerida}"
ARCHIVO="/tmp/disponibilidad_${NOMBRE}.log"
echo "Monitoreando $NOMBRE..."
echo "Fecha UTC | Estado" | tee "$ARCHIVO"
for i in $(seq 1 300); do
  FECHA=$(date -u '+%Y-%m-%d %H:%M:%S')
  if MYSQL_PWD="$CLAVE" mysql --connect-timeout=3 -h "$HOST" -u "$USUARIO" medibook \
       -N -e "SELECT 1;" >/dev/null 2>&1; then
    ESTADO="OK"
  else
    ESTADO="ERROR"
  fi
  echo "$FECHA | $ESTADO" | tee -a "$ARCHIVO"
  sleep 2
done
