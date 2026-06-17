# SistemasOCD-Semana14-archivo.md
#!/bin/bash

# Configura la dirección IP o dominio a verificar
HOST="google.com"

# Realiza un ping de 3 paquetes
if ping -c 3 "$HOST" &> /dev/null
then
    echo "Conexión exitosa a $HOST"
else
    echo "Error: No se pudo conectar a $HOST"
fi
