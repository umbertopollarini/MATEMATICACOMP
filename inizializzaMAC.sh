#!/bin/bash

echo "Rilevamento del gestore di pacchetti e installazione di Python..." >> outputScript.txt

# Assicura che Homebrew sia installato e installa Python se necessario
if command -v brew > /dev/null 2>&1; then
    echo "Utilizzando Homebrew per installare Python..." >> outputScript.txt
    brew install python3
else
    echo "Homebrew non è installato. Installazione di Homebrew..." >> outputScript.txt
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew installato. Installazione di Python..." >> outputScript.txt
    brew install python3
fi

echo "Creazione e attivazione di un ambiente virtuale Python..." >> outputScript.txt
python3 -m venv venv
source venv/bin/activate

echo "Installazione dei pacchetti Python necessari..." >> outputScript.txt
pip3 install fifteen_puzzle_solvers
pip3 install watchdog

echo "Avvio dello script..." >> outputScript.txt
python3 risolutore.py &

echo "Script in esecuzione in background. Puoi chiudere la sessione del terminale." >> outputScript.txt
deactivate
