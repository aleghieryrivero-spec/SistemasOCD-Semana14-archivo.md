#!/bin/bash
# Restauración total del laboratorio vaciando las reglas aplicadas en el firewall
iptables -F INPUT

# Restablecimiento de las políticas por defecto del filtro de paquetes a modo permisivo
iptables -P INPUT ACCEPT

# Reinicio de Apache para normalizar los hilos de procesamiento y descriptores de sockets
systemctl restart apache2
