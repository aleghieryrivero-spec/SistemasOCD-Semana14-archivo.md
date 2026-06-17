#!/bin/bash

HOST="google.com"

if ping -c 3 "$HOST" &> /dev/null
then
    echo "✅ Conexión exitosa a $HOST"
else
    echo "❌ Error: No se pudo conectar a $HOST"
fi
