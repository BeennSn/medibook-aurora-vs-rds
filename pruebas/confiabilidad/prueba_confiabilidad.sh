#!/usr/bin/env bash
set -u
# Ejecutar desde una instancia con acceso a ambas bases de datos.
# Requiere las seis variables: AURORA_HOST, AURORA_USER, AURORA_PASS,
# RDS_HOST, RDS_USER, RDS_PASS.

probar() {
  local NOMBRE="$1" HOST="$2" USUARIO="$3" CLAVE="$4"
  local A B
  A="$(mktemp)"; B="$(mktemp)"
  echo ""
  echo "========== $NOMBRE =========="
  MYSQL_PWD="$CLAVE" mysql -h "$HOST" -u "$USUARIO" medibook \
    -e "DELETE FROM citas WHERE medico_id=1 AND fecha='2026-11-15' AND hora='10:00:00';" || return 1
  (
    MYSQL_PWD="$CLAVE" mysql -h "$HOST" -u "$USUARIO" medibook \
      -e "INSERT INTO citas (paciente_id,medico_id,fecha,hora) VALUES (1,1,'2026-11-15','10:00:00');" \
      > "$A" 2>&1
    echo "Resultado paciente A: codigo $?"
  ) &
  (
    MYSQL_PWD="$CLAVE" mysql -h "$HOST" -u "$USUARIO" medibook \
      -e "INSERT INTO citas (paciente_id,medico_id,fecha,hora) VALUES (2,1,'2026-11-15','10:00:00');" \
      > "$B" 2>&1
    echo "Resultado paciente B: codigo $?"
  ) &
  wait
  cat "$A" "$B"
  rm -f "$A" "$B"
  MYSQL_PWD="$CLAVE" mysql -h "$HOST" -u "$USUARIO" medibook \
    -e "SELECT id,paciente_id,medico_id,fecha,hora,estado FROM citas WHERE medico_id=1 AND fecha='2026-11-15'; SELECT COUNT(*) AS reservas_confirmadas FROM citas WHERE medico_id=1 AND fecha='2026-11-15' AND hora='10:00:00';"
}

: "${AURORA_HOST:?Falta AURORA_HOST}" "${AURORA_USER:?Falta AURORA_USER}" "${AURORA_PASS:?Falta AURORA_PASS}"
: "${RDS_HOST:?Falta RDS_HOST}" "${RDS_USER:?Falta RDS_USER}" "${RDS_PASS:?Falta RDS_PASS}"
probar "AMAZON AURORA" "$AURORA_HOST" "$AURORA_USER" "$AURORA_PASS"
probar "AMAZON RDS MYSQL" "$RDS_HOST" "$RDS_USER" "$RDS_PASS"
