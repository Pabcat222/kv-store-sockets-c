#!/bin/bash
# Función llamada por la señal SIGINT configurada con trap
cleanup() {
    echo "Interrumpido. Matando procesos..."
    pkill -P $$  # Mata todos los procesos hijos del script
    exit 1
}
# Capturar SIGINT (Ctrl+C)
trap cleanup SIGINT


LD_LIBRARY_PATH=. ./cliente &
LD_LIBRARY_PATH=. ./cliente1 &
LD_LIBRARY_PATH=. ./cliente2 &
LD_LIBRARY_PATH=. ./cliente3 &
LD_LIBRARY_PATH=. ./cliente4 &
LD_LIBRARY_PATH=. ./cliente5 &
LD_LIBRARY_PATH=. ./cliente6 


wait

exit 0