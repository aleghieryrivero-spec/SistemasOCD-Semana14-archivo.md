#!/usr/bin/env bash
set -euo pipefail

CHAIN_L4="SYN_RATE_LIMIT"
PUERTO=80

# Limpieza idempotente
if iptables -L "$CHAIN_L4" -n &>/dev/null 2>&1; then
    iptables -F "$CHAIN_L4"
    iptables -D INPUT -p tcp --dport "$PUERTO" -j "$CHAIN_L4" 2>/dev/null || true
    iptables -X "$CHAIN_L4"
fi

if iptables -C INPUT -p tcp --dport "$PUERTO" \
     -m string --string "db.sql" --algo bm -j DROP 2>/dev/null; then
    iptables -D INPUT -p tcp --dport "$PUERTO" \
        -m string --string "db.sql" --algo bm -j DROP
fi

# Defensa Capa 4 — Rate Limiting SYN
iptables -N "$CHAIN_L4"
iptables -A "$CHAIN_L4" -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
iptables -A "$CHAIN_L4" -p tcp --syn -j DROP
iptables -A INPUT -p tcp --dport "$PUERTO" -j "$CHAIN_L4"

# Defensa Capa 7 — Bloqueo de db.sql
iptables -I INPUT -p tcp --dport "$PUERTO" \
    -m string --string "db.sql" --algo bm -j DROP

echo "Defensa activa. Reglas L4 y L7 aplicadas."
iptables -L INPUT -n -v --line-numbers

