#!/usr/bin/env bash
# =============================================================================
# defensa.sh — Mitigación dual: SYN Flood (L4) + HTTP String Matching (L7)
# Curso : Sistemas Operativos de Código Abierto — Guía de Laboratorio 15
# Entorno: Ubuntu Server 26 | VMware NAT 10.160.10.0/24
# Autor  : Aleghiery Williams Rivero Roman
# =============================================================================
set -euo pipefail

# ── Colores para salida legible ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; exit 1; }

# ── Verificar privilegios ────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Este script debe ejecutarse como root (sudo)."

# ── Constantes ───────────────────────────────────────────────────────────────
CHAIN_L4="SYN_RATE_LIMIT"
PUERTO=80
LIMITE_SYN="10/s"
LIMITE_BURST=20
ARCHIVO_BLOQUEADO="db.sql"
ALGO_STRING="bm"           # Boyer-Moore, más eficiente que kmp para cadenas cortas

# =============================================================================
# FASE DE LIMPIEZA — Regla HP de Oro: idempotencia garantizada
# =============================================================================
limpiar_reglas() {
    warn "Limpiando reglas anteriores del laboratorio..."

    # Eliminar cadena personalizada si existe (evita duplicados)
    if iptables -L "$CHAIN_L4" -n &>/dev/null 2>&1; then
        iptables -F "$CHAIN_L4"
        iptables -D INPUT -p tcp --dport "$PUERTO" -j "$CHAIN_L4" 2>/dev/null || true
        iptables -X "$CHAIN_L4"
        log "Cadena $CHAIN_L4 eliminada."
    fi

    # Eliminar regla de string matching L7 si existe
    if iptables -C INPUT -p tcp --dport "$PUERTO" \
         -m string --string "$ARCHIVO_BLOQUEADO" --algo "$ALGO_STRING" -j DROP \
         2>/dev/null; then
        iptables -D INPUT -p tcp --dport "$PUERTO" \
            -m string --string "$ARCHIVO_BLOQUEADO" --algo "$ALGO_STRING" -j DROP
        log "Regla L7 (string matching) eliminada."
    fi

    warn "Limpieza completada. Aplicando reglas nuevas..."
}

# =============================================================================
# DEFENSA CAPA 4 — Rate Limiting contra SYN Flood
# =============================================================================
defensa_capa4() {
    log "Configurando Rate Limiting SYN (Capa 4 / Kernel)..."

    # Crear cadena dedicada para mantener el firewall organizado
    iptables -N "$CHAIN_L4"

    # Aceptar SYN dentro del límite establecido
    iptables -A "$CHAIN_L4" -p tcp --syn \
        -m limit --limit "$LIMITE_SYN" --limit-burst "$LIMITE_BURST" \
        -j ACCEPT

    # DROP silencioso para el exceso (no responde RST, no alimenta al atacante)
    iptables -A "$CHAIN_L4" -p tcp --syn -j DROP

    # Enrutar tráfico HTTP hacia la cadena dedicada
    iptables -A INPUT -p tcp --dport "$PUERTO" -j "$CHAIN_L4"

    log "Rate Limiting activo: máximo $LIMITE_SYN (burst $LIMITE_BURST) en puerto $PUERTO."
}

# =============================================================================
# DEFENSA CAPA 7 — HTTP String Matching para bloquear descarga de db.sql
# =============================================================================
defensa_capa7() {
    log "Configurando filtro HTTP Layer 7 (String Matching)..."

    # Bloquear peticiones que contengan la cadena "db.sql" en el payload TCP
    iptables -I INPUT -p tcp --dport "$PUERTO" \
        -m string --string "$ARCHIVO_BLOQUEADO" --algo "$ALGO_STRING" \
        -j DROP

    # NOTA: -I (Insert) coloca esta regla ANTES de la cadena L4,
    # garantizando que las descargas masivas se eliminen primero.
    log "Filtro L7 activo: DROP de peticiones que contengan '$ARCHIVO_BLOQUEADO'."
}

# =============================================================================
# VERIFICACIÓN POST-APLICACIÓN
# =============================================================================
verificar() {
    log "Estado actual de las reglas aplicadas:"
    echo ""
    iptables -L INPUT -n -v --line-numbers
    echo ""
    iptables -L "$CHAIN_L4" -n -v --line-numbers 2>/dev/null || true
    echo ""
    log "Defensa activa. Monitorea con: watch -n1 'iptables -L INPUT -n -v'"
}

# =============================================================================
# PUNTO DE ENTRADA PRINCIPAL
# =============================================================================
main() {
    echo ""
    echo "============================================================"
    echo "  defensa.sh — Lab 15 Troubleshooting | SysOCD Tecsup"
    echo "============================================================"
    echo ""

    limpiar_reglas
    defensa_capa4
    defensa_capa7
    verificar

    echo ""
    log "Script finalizado exitosamente. El servidor Apache está protegido."
    echo ""
}

main "$@"
