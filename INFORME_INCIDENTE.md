# Informe de Mitigación de Incidentes - Laboratorio 15

## Fase 1 y 2: Diagnóstico e Identificación del Ataque
El atacante utiliza IP Spoofing, lo que significa que cambia su dirección IP en cada paquete que envía de forma automatizada por lo que bloquear una sola IP es inútil porque la siguiente solicitud provendrá de una dirección completamente diferente y bloquear IPs individuales humanamente imposible seguirle el ritmo. El fallo es un ataque mixto alojado en la Capa de Red/Transporte (Capa 4) por una inundación SYN con spoofing que satura los sockets del Kernel en SYN-RECV, impactando colateralmente a la Capa de Aplicación (Capa 7) debido a descargas concurrentes de db.sql, lo que rompe la infraestructura de red del sistema operativo antes de que Apache pueda procesar a los usuarios legítimos.

## Fase 3 y 4: Plan de Acción y Ejecución
El plan consistió en estructurar un script de firewall idempotente que prioriza la subred interna y mitiga simultáneamente ambos vectores de ataque. El tiempo de carga del juego web regresa por completo a la normalidad debido a que el reinicio del servicio con `sudo systemctl restart apache2` destruyó las sesiones TCP ya establecidas que el atacante mantenía abiertas, forzando a que sus nuevas solicitudes automatizadas choquen directamente contra las reglas de `iptables`.

### Evidencia de la Operación del Firewall
Tras aplicar la defensa, la inspección en tiempo real confirma la mitigación efectiva:
* **Regla SYN Flood (Capa 4):** Registra 5,721 paquetes maliciosos descartados (DROP).
* **Regla String Match (Capa 7):** Registra 241 paquetes de descarga "GET /db.sql" bloqueados (DROP).

## Fase 5 y 6: Verificación y Prevención
El tráfico de salida (TX) en `nload` y la utilización de disco (`%util`) en `iostat` cayeron por completo a niveles normales de reposo absoluto debido a que la combinación del script de firewall y el comando `sudo systemctl restart apache2` destruyó las conexiones TCP preexistentes del atacante. Para automatizar la protección preventiva basada en un umbral de peligro, configuraría una tarea programada en Cron ejecutada cada minuto mediante la directiva `* * * * * /usr/local/bin/check_traffic.sh` que verifique si los paquetes de red superan el límite crítico y dispare automáticamente el script de mitigación.
