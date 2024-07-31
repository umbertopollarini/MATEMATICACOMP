#!/bin/bash

# Directory corrente
CURRENT_DIR=$(pwd)

# Variabile per il percorso dell'ambiente virtuale
VENV_DIR="$CURRENT_DIR/venv"

echo "Rilevamento del gestore di pacchetti e installazione di Python..." >> outputScript.txt

# Installa Python se non già installato
if command -v apt-get > /dev/null 2>&1; then
    echo "Utilizzando APT per installare Python..." >> outputScript.txt
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip
elif command -v dnf > /dev/null 2>&1; then
    echo "Utilizzando DNF per installare Python..." >> outputScript.txt
    sudo dnf install -y python3 python3-venv python3-pip
elif command -v yum > /dev/null 2>&1; then
    echo "Utilizzando YUM per installare Python..." >> outputScript.txt
    sudo yum install -y python3 python3-venv python3-pip
elif command -v zypper > /dev/null 2>&1; then
    echo "Utilizzando Zypper per installare Python..." >> outputScript.txt
    sudo zypper install -y python3 python3-venv python3-pip
elif command -v pacman > /dev/null 2>&1; then
    echo "Utilizzando Pacman per installare Python..." >> outputScript.txt
    sudo pacman -Sy python python-pip python-virtualenv
else
    echo "Gestore di pacchetti non trovato. Installazione di Python non riuscita." >> outputScript.txt
    exit 1
fi

# Creazione dell'ambiente virtuale
echo "Creazione dell'ambiente virtuale Python..." >> outputScript.txt
python3 -m venv "$VENV_DIR"

# Verifica della creazione dell'ambiente virtuale
if [ ! -d "$VENV_DIR" ]; then
    echo "Errore nella creazione dell'ambiente virtuale." >> outputScript.txt
    exit 1
fi

# Attivazione dell'ambiente virtuale
echo "Attivazione dell'ambiente virtuale Python..." >> outputScript.txt
. "$VENV_DIR/bin/activate"

# Verifica se l'ambiente virtuale è attivo
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Errore: l'ambiente virtuale non è stato attivato." >> outputScript.txt
    exit 1
fi

# Installazione dei pacchetti Python necessari
echo "Installazione dei pacchetti Python necessari..." >> outputScript.txt
pip install fifteen_puzzle_solvers watchdog

# Verifica dell'installazione di python3-tk
echo "Installazione di python3-tk..." >> outputScript.txt
if command -v apt-get > /dev/null 2>&1; then
    sudo apt-get install -y python3-tk
elif command -v dnf > /dev/null 2>&1; then
    sudo dnf install -y python3-tkinter
elif command -v yum > /dev/null 2>&1; then
    sudo yum install -y python3-tkinter
elif command -v zypper > /dev/null 2>&1; then
    sudo zypper install -y python3-tk
elif command -v pacman > /dev/null 2>&1; then
    sudo pacman -Sy python-tk
else
    echo "Gestore di pacchetti non trovato. Installazione di python3-tk non riuscita." >> outputScript.txt
    exit 1
fi

# Avvio dello script Python
echo "Avvio dello script..." >> outputScript.txt
python3 risolutore.py &

# Disattivazione dell'ambiente virtuale
echo "Disattivazione dell'ambiente virtuale..." >> outputScript.txt
deactivate

echo "Script in esecuzione in background. Puoi chiudere la sessione del terminale." >> outputScript.txt
