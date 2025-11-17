#!/bin/bash
# DNS Dinámico WHM con TTL adaptable

# ================= CONFIGURACIÓN =================
WHM_URL="https://josefina.servidorlinux15.com:2087"
WHM_USER="TU_USUARIO_DE_WHM"   
WHM_PASS="TU_CONTRASEÑA_DE_WHM_AQUI"
ZONA_DNS="TU_DOMINIO_AQUI"
SUBDOMINIO="TU_SUB_DOMINIO_AQUI"
TTL_TEMPORAL=300    # TTL bajo para propagación rápida
# ===============================================

ROJO='\033[0;31m'; VERDE='\033[0;32m'; AZUL='\033[0;34m'; NC='\033[0m'

# 1. IP Pública
IP_ACTUAL=$(curl -s https://api.ipify.org)
echo -e "${AZUL}[1/6]${NC} IP actual: ${IP_ACTUAL}"

# 2. Obtener registro actual + TTL original
RESPUESTA=$(curl -s -k -u "${WHM_USER}:${WHM_PASS}" \
  "${WHM_URL}/json-api/dumpzone?api.version=1&domain=${ZONA_DNS}")

# Extraer línea, IP actual y TTL original
LINEA=$(echo "$RESPUESTA" | jq -r --arg NAME "${SUBDOMINIO}." '
  .data.zone[0].record[] | select(.name == $NAME and .type == "A") | .Line')

[ -z "$LINEA" ] && echo -e "${ROJO}✗${NC} Registro no encontrado" && exit 1

TTL_ORIGINAL=$(echo "$RESPUESTA" | jq -r --arg NAME "${SUBDOMINIO}." '
  .data.zone[0].record[] | select(.name == $NAME and .type == "A") | .ttl')

IP_ANTIGUA=$(echo "$RESPUESTA" | jq -r --arg NAME "${SUBDOMINIO}." '
  .data.zone[0].record[] | select(.name == $NAME and .type == "A") | .address')

echo -e "${VERDE}✓${NC} Registro: línea $LINEA | IP: $IP_ANTIGUA | TTL: ${TTL_ORIGINAL}s"

# 3. Si IP no cambió, salir
if [ "$IP_ACTUAL" = "$IP_ANTIGUA" ]; then
    echo -e "${AZUL}[2/6]${NC} IP sin cambios, nada que hacer"
    exit 0
fi

# 4. REDUCIR TTL si es necesario
if [ "$TTL_ORIGINAL" -gt "$TTL_TEMPORAL" ]; then
    echo -e "${AZUL}[3/6]${NC} Reduciendo TTL de ${TTL_ORIGINAL}s a ${TTL_TEMPORAL}s..."
    SERIAL=$(echo "$RESPUESTA" | jq -r '.data.zone[0].record[] | select(.type == "SOA") | .serial')
    
    curl -s -k -u "${WHM_USER}:${WHM_PASS}" -X POST \
      "${WHM_URL}/json-api/editzonerecord" \
      -d "api.version=1" -d "domain=${ZONA_DNS}" -d "type=A" \
      -d "address=${IP_ANTIGUA}" -d "ttl=${TTL_TEMPORAL}" \
      -d "serial=${SERIAL}" -d "class=IN" -d "line=${LINEA}" >/dev/null
    
    echo -e "${VERDE}✓${NC} TTL reducido"
    sleep 2  # Esperar a que se aplique
fi

# 5. ACTUALIZAR IP
echo -e "${AZUL}[4/6]${NC} Actualizando IP: ${IP_ANTIGUA} → ${IP_ACTUAL}"
SERIAL=$(echo "$RESPUESTA" | jq -r '.data.zone[0].record[] | select(.type == "SOA") | .serial')

UPDATE=$(curl -s -k -u "${WHM_USER}:${WHM_PASS}" -X POST \
  "${WHM_URL}/json-api/editzonerecord" \
  -d "api.version=1" -d "domain=${ZONA_DNS}" -d "type=A" \
  -d "address=${IP_ACTUAL}" -d "ttl=${TTL_TEMPORAL}" \
  -d "serial=${SERIAL}" -d "class=IN" -d "line=${LINEA}")

echo "$UPDATE" | jq -e '.metadata.result == 1' >/dev/null || {
    echo -e "${ROJO}✗${NC} Falló: $(echo "$UPDATE" | jq -r '.metadata.reason')"
    exit 1
}
echo -e "${VERDE}✓${NC} IP actualizada"

# 6. RESTAURAR TTL original
echo -e "${AZUL}[5/6]${NC} Restaurando TTL a ${TTL_ORIGINAL}s..."
UPDATE=$(curl -s -k -u "${WHM_USER}:${WHM_PASS}" -X POST \
  "${WHM_URL}/json-api/editzonerecord" \
  -d "api.version=1" -d "domain=${ZONA_DNS}" -d "type=A" \
  -d "address=${IP_ACTUAL}" -d "ttl=${TTL_ORIGINAL}" \
  -d "serial=${SERIAL}" -d "class=IN" -d "line=${LINEA}")

echo "$UPDATE" | jq -e '.metadata.result == 1' >/dev/null || {
    echo -e "${ROJO}✗${NC} Falló restauración: $(echo "$UPDATE" | jq -r '.metadata.reason')"
    exit 1
}
echo -e "${VERDE}✓${NC} TTL restaurado"

# 7. Verificar propagación
echo -e "${AZUL}[6/6]${NC} Verificando DNS..."
sleep 2
IP_GOOGLE=$(dig +short $SUBDOMINIO @8.8.8.8)
echo -e "${VERDE}✓${NC} Completado. IP en Google DNS: ${IP_GOOGLE}"

# Salida resumen
echo -e "\n${VERDE}✓✓✓ RESUMEN:${NC}"
echo "  Subdominio: ${SUBDOMINIO}"
echo "  IP Anterior: ${IP_ANTIGUA}"
echo "  IP Nueva: ${IP_ACTUAL}"
echo "  TTL: ${TTL_ORIGINAL}s (temporalmente ${TTL_TEMPORAL}s)"
echo "  Propagación estimada: ${TTL_TEMPORAL} segundos (~5 min)"
