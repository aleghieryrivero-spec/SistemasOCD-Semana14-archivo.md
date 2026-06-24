#!/bin/bash
# =====================================================================
# GUÍA DE LABORATORIO 15 - SCRIPT DE MITIGACIÓN
# =====================================================================

echo "[+] Iniciando Plan de Acción y Despliegue de Contención..."

# 1. LIMPIEZA / IDEMPOTENCIA
# Remueve reglas previas que contengan la etiqueta de control para evitar duplicados
iptables-save | grep -v "#LAB15" | iptables-restore

# 2. MITIGACIÓN CAPA 4: Control de Inundación SYN (SYN Flood Rate Limiting)
# Limita las conexiones nuevas (SYN) por minuto desde cualquier origen
iptables -A INPUT -p tcp --syn -m limit --limit 20/minute --limit-burst 50 -j ACCEPT -m comment --comment "#LAB15"
iptables -A INPUT -p tcp --syn -j DROP -m comment --comment "#LAB15"

# 3. MITIGACIÓN CAPA 7: Bloqueo por Inspección de Cadenas (String Matching)
# Detecta e intercepta la petición HTTP antes de que Apache lea el disco duro
iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string "GET /db.sql" -j DROP -m comment --comment "#LAB15"

echo "[+] Filtros aplicados exitosamente. Sistema protegido sin desconectar usuarios."
