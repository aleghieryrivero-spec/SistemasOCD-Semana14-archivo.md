#!/usr/bin/env bash
# =============================================================================
# reset_lab.sh — Restauración completa del entorno post-laboratorio
# Curso : Sistemas Operativos de Código Abierto — Guía de Laboratorio 15
# Entorno: Ubuntu Server 26 | VMware NAT 10.160.10.0/24
# Autor  : Aleghiery Williams Rivero Roman
# ADVERTENCIA: Este script elimina TODAS las reglas de iptables.
#              Úsalo SOLO en el entorno de laboratorio aislado.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; exit 1; }

[[ $EUID -ne 0 ]] && err "Requiere root. Usa: sudo ./reset_lab.sh"

echo ""
echo "============================================================"
echo "  reset_lab.sh — Restauración del Entorno Lab 15"
echo "============================================================"
echo ""
warn "Este script eliminará TODAS las reglas de iptables activas."
read -r -p "¿Continuar? (s/N): " confirm
[[ "${confirm,,}" != "s" ]] && { info "Operación cancelada."; exit 0; }

echo ""

# ── 1. Vaciar todas las cadenas (INPUT, OUTPUT, FORWARD) ─────────────────────
log "Vaciando todas las cadenas de iptables..."
iptables -F
log "Cadenas vaciadas (iptables -F)."

# ── 2. Eliminar cadenas personalizadas ───────────────────────────────────────
log "Eliminando cadenas personalizadas..."
iptables -X 2>/dev/null && log "Cadenas personalizadas eliminadas." \
    || warn "No había cadenas personalizadas que eliminar."

# ── 3. Restaurar políticas por defecto (ACCEPT) ──────────────────────────────
log "Restaurando políticas por defecto a ACCEPT..."
iptables -P INPUT   ACCEPT
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD ACCEPT
log "Políticas restauradas."

# ── 4. Verificación del estado limpio ────────────────────────────────────────
echo ""
log "Estado de iptables tras el reset:"
iptables -L -n -v
echo ""

# ── 5. Verificar conectividad con Apache ─────────────────────────────────────
log "Verificando que Apache responde (curl localhost)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
    log "Apache responde correctamente. Entorno restaurado."
else
    warn "Apache no responde en localhost. Verifica el servicio: systemctl status apache2"
fi

echo ""
log "Reset completado. El entorno de laboratorio está en estado inicial."
echo ""
