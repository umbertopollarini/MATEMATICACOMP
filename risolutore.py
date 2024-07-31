from fifteen_puzzle_solvers.domain import Puzzle
from fifteen_puzzle_solvers.services.algorithms import AStar, BreadthFirst
from fifteen_puzzle_solvers.services.solver import PuzzleSolver
import os
import json
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time

# Classe che estende PuzzleSolver per tracciare il numero di mosse
class TrackingPuzzleSolver(PuzzleSolver):
    def __init__(self, algorithm):
        super().__init__(algorithm)
        self.algorithm = algorithm
        self.move_count = 0

    # Esegue l'algoritmo e conta le mosse
    def run(self):
        super().run()
        if hasattr(self.algorithm, 'solution'):
            self.move_count = len(self.algorithm.solution) - 1

    # Scrive il numero di mosse in un file
    def print_move_count(self):
        file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'mosse.txt')
        with open(file_path, 'w') as file:
            file.write(f"{self.move_count}\n")

    # Scrive la soluzione passo per passo in un file
    def print_solution(self):
        file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'soluzione.txt')
        with open(file_path, 'w', encoding="utf-8") as file:
            move_number = 1
            for state in self.algorithm.solution:
                file.write(f"Step {move_number}:\n{state}\n")
                move_number += 1

# Carica il puzzle da un file JSON
def load_puzzle_from_json(file_path):
    with open(file_path, 'r', encoding="utf-8") as file:
        data = json.load(file)
    return data

# Gestore di eventi che rileva la creazione di nuovi file
class FileCreatedHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory and os.path.basename(event.src_path) == "gameState.json":
            print("File gameState.json creato, inizio del processo.")
            time.sleep(1)

            loaded = False
            while not loaded:
                try:
                    puzzle_data = load_puzzle_from_json(event.src_path)
                    loaded = True
                except json.JSONDecodeError:
                    print("Errore nella decodifica del JSON, riprovo...")
                    time.sleep(1) 

            puzzle = Puzzle(puzzle_data)
            print("Puzzle caricato:\n", puzzle)

            try:
                puzzle_solver = TrackingPuzzleSolver(AStar(puzzle))
                puzzle_solver.run()
                puzzle_solver.print_performance()
                puzzle_solver.print_solution()
                puzzle_solver.print_move_count()
            except RuntimeError as e:
                print("Errore:", e)
                os.remove(event.src_path)
                print("File gameState.json eliminato a causa di un errore.")
            finally:
                if os.path.exists(event.src_path):
                    os.remove(event.src_path)
                    print("File gameState.json eliminato dopo l'elaborazione.")

if __name__ == "__main__":
    path = os.path.dirname(os.path.realpath(__file__))
    gameState_file_path = os.path.join(path, "gameState.json")

    # Controllo se il file gameState.json esiste e lo elimino se presente
    if os.path.exists(gameState_file_path):
        os.remove(gameState_file_path)
        print("File gameState.json preesistente trovato e eliminato.")

    # Imposta il gestore di eventi per rilevare la creazione di nuovi file
    event_handler = FileCreatedHandler()
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    observer.start()
    print("In attesa della creazione di gameState.json nella directory:", path)
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        observer.join()
