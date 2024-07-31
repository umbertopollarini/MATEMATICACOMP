(* ::Package:: *)

BeginPackage["Gioco8`"]
(* Esportazione delle funzioni *)

InterfacciaGioco::usage = "InterfacciaGioco[] avvia l'interfaccia grafica del gioco.";
(* Esportazione delle funzioni *)

(*
InterfacciaGioco::usage = "InterfacciaGioco[] avvia l'interfaccia grafica del gioco.";
ControllaVittoria::usage = "ControllaVittoria[stato] verifica se lo stato attuale \[EGrave] una configurazione vincente.";
IniziaGioco::usage = "IniziaGioco[seed] inizializza il gioco con un dato seed.";
MossePossibili::usage = "MossePossibili[stato] restituisce una lista di mosse possibili a partire dallo stato attuale.";
Muovi::usage = "Muovi[stato, {ni, nj}] muove la tessera vuota nella posizione specificata.";
SalvaMosse::usage = "SalvaMosse[filepath] salva le mosse dell'utente in un file.";
SalvaConfigurazione::usage = "SalvaConfigurazione[stato, filepath] salva lo stato attuale del gioco in un file JSON.";
ConfigurazioneNonSolubile::usage = "ConfigurazioneNonSolubile[stato] verifica se una configurazione del gioco \[EGrave] insolubile.";
GetMoves::usage = "GetMoves[] restituisce il numero di mosse attuali.";
SetPlayerName::usage = "SetPlayerName[name] imposta il nome del giocatore.";
ResetGioco::usage = "ResetGioco[seed] reimposta lo stato del gioco con un nuovo seed.";
ResetMosse::usage = "ResetMosse[] reimposta il contatore delle mosse.";
mostraSoluzioneButton::usage = "mostraSoluzioneButton[filename] mostra le finestre di dialogo per la soluzione e le mosse dell'utente.";
aggiornaGrafica::usage = "aggiornaGrafica[Dynamic[stato]] aggiorna la grafica del gioco.";
*)
Begin["`Private`"]

(*Avviamento Script Processore Soluzioni*)
Directory[]
Switch[$OperatingSystem,
"MacOSX",
If[Run["sh inizializzaMAC.sh"]==0,
Print["AVVIATO CORRETTAMENTE"],
Print["AVVIO IN CORSO..."]
],
"Unix",
If[Run["sh inizializza.sh"]==0,
Print["AVVIATO CORRETTAMENTE"],
Print["AVVIO IN CORSO..."]
],
"Windows",
If[Run["inizializza.bat"]==0,
Print["AVVIATO CORRETTAMENTE"],
Print["AVVIO IN CORSO..."]
],
_,
Print["Sistema operativo non supportato"]
]

(* Variabili globali *)
(* Getter e Setter per moves *)
GetMoves[] := moves;
SetMoves[val_Integer] := moves = val;

(* Getter e Setter per playerName *)
GetPlayerName[] := playerName;
SetPlayerName[name_String] := playerName = name;

(* Getter e Setter per movesList *)
GetMovesList[] := movesList;
SetMovesList[val_List] := movesList = val;
AddToMovesList[item_] := AppendTo[movesList, item];

(* Getter e Setter per currentSeed *)
GetCurrentSeed[] := currentSeed;
SetCurrentSeed[val_] := currentSeed = val;

(* Funzione per la verifica della vittoria *)
ControllaVittoria[stato_] := Flatten[stato] === Range[1, 8] ~Append~ 0;

(* Inizializzazione del gioco *)
IniziaGioco[seed_: Automatic] := Module[{numeri},
    SetCurrentSeed[If[seed === Automatic, RandomInteger[{1, 1000000}], seed]];
    SeedRandom[GetCurrentSeed[]];
    numeri = RandomSample[Range[0, 8]];
    Partition[numeri, 3]
];

ConfigurazioneNonSolubile[stato_] := Module[{flattened, inversions},
    flattened = DeleteCases[Flatten[stato], 0];
    inversions = Count[Flatten[Table[
        If[i < j && flattened[[i]] > flattened[[j]], 1, 0],
        {i, Length[flattened]}, {j, Length[flattened]}]], 1];
    OddQ[inversions]
];

(* Determinazione delle mosse possibili *)
MossePossibili[stato_] := Module[{vuotoPos, i, j},
    vuotoPos = Position[stato, 0][[1]];
    {i, j} = vuotoPos;
    DeleteCases[{If[i > 1, {i - 1, j}, Null], If[i < 3, {i + 1, j}, Null], 
                 If[j > 1, {i, j - 1}, Null], If[j < 3, {i, j + 1}, Null]}, Null]
];
GetMoves[] := moves;

Muovi[stato_, {ni_, nj_}] := Module[{nuovoStato, vuotoPos, i, j, mosseOttimali},
    nuovoStato = stato;
    vuotoPos = Position[stato, 0][[1]];
    {i, j} = vuotoPos;
    If[MemberQ[MossePossibili[stato], {ni, nj}],
       nuovoStato[[i, j]] = nuovoStato[[ni, nj]];
       nuovoStato[[ni, nj]] = 0;
       SetMoves[GetMoves[] + 1];
       AddToMovesList[nuovoStato];
       If[ControllaVittoria[nuovoStato],
          mosseOttimali = LeggiMosseOttimali[];
          MessageDialog[TemplateApply[
            "Congratulazioni! Hai completato il gioco in `moves` mosse. Il numero ottimale di mosse \[EGrave] `optimalMoves`.",
            <|"moves" -> GetMoves[], "optimalMoves" -> mosseOttimali|>
          ]];
       ];
    ];
    nuovoStato
];


LeggiMosseOttimali[] := Module[{file, mosseOttimali},
    file = OpenRead[FileNameJoin[{NotebookDirectory[], "mosse.txt"}]]; (* Aggiusta il percorso se necessario *)
    mosseOttimali = Read[file, Number];
    Close[file];
    mosseOttimali
];

(* Salva le mosse e lo stato in un formato leggibile su file *)
SalvaMosse[filepath_] := Module[{file, moveNum = 1, movesList = GetMovesList[], currentSeed = GetCurrentSeed[]},
    file = OpenWrite[filepath, CharacterEncoding -> "UTF8"];
    WriteString[file, "Seed: ", currentSeed, "\n\n"];
    For[moveNum = 1, moveNum <= Length[movesList], moveNum++,
        WriteString[file, "Step ", moveNum, ":\n-----------------\n"];
        Scan[(WriteString[file, "| ", StringJoin[Riffle[ToString /@ #, " | "]], " |\n"] &), movesList[[moveNum]]];
        WriteString[file, "-----------------\n\n"];
    ];
    Close[file];
];

(* Salva lo stato corrente del gioco in un file JSON *)
SalvaConfigurazione[stato_, filepath_] := Module[{json},
    json = ExportString[stato, "RawJSON"];
    Export[filepath, json, "Text"];
];

(* Visualizzazione della soluzione e delle mosse *)

(* Visualizzazione della soluzione e delle mosse *)
mostraSoluzioneButton[filename_] := Button["Show Solution",
    Module[{filepath = FileNameJoin[{NotebookDirectory[], filename}], solutionData, userMovesData, screenInfo, screenWidth, screenHeight, leftMargin, rightMargin, dialogWidth = 550},
        solutionData = Import[filepath, "Text"];
        SalvaMosse[FileNameJoin[{NotebookDirectory[], "userMoves.txt"}]];
        userMovesData = Import[FileNameJoin[{NotebookDirectory[], "userMoves.txt"}], "Text"];

        (* Ottieni le informazioni sullo schermo e verifica *)
        screenInfo = CurrentValue["ScreenArea"];
        If[MatchQ[screenInfo, {{_, _}, {_, _}}],
            {screenWidth, screenHeight} = screenInfo /. {{left_, top_}, {right_, bottom_}} :> {right - left, bottom - top},
            (* Se non \[EGrave] possibile ottenere le dimensioni dello schermo, usa valori di default *)
            {screenWidth, screenHeight} = {1920, 1080};  (* Assumi una risoluzione comune se il valore non \[EGrave] disponibile *)
        ];

        (* Calcola i margini per posizionare le finestre sui lati opposti dello schermo evitando di uscire dallo schermo *)
        leftMargin = 50;  (* Margin sufficientemente dentro dal bordo sinistro *)
        rightMargin = screenWidth - dialogWidth - 50;  (* Distanza adeguata dal bordo destro *)

        CreateDialog[Pane[Style[solutionData, "Text", FontFamily -> "Courier"], {500, 300}, Scrollbars -> True],
                     WindowTitle -> "Solution ", WindowSize -> {dialogWidth, 350}, 
                     WindowMargins -> {{leftMargin, Automatic}, {Automatic, Automatic}}];   (* A sinistra *)

        CreateDialog[Pane[Style[userMovesData, "Text", FontFamily -> "Courier"], {500, 300}, Scrollbars -> True],
                     WindowTitle -> "Your Moves", WindowSize -> {dialogWidth, 350},
                     WindowMargins -> {{rightMargin, Automatic}, {Automatic, Automatic}}];  (* A destra *)
    ], ImageSize -> {250, 40}];

(* Reimpostazione del gioco *)
ResetGioco[seed_: Automatic] := Module[{stato, notebooks},
    notebooks = Notebooks[];
    excludedTitles = {"giocodell8.nb", "packagegiocodell8.wl"};

    notebooks = Notebooks[];
    Do[If[Not[MemberQ[excludedTitles, ("WindowTitle" /. NotebookInformation[nb])]],
         NotebookClose[nb]],
       {nb, notebooks}];
    SetMoves[0];
    SetMovesList[{}];
    stato = IniziaGioco[seed];
    stato
];

ResetMosse[] := (
    SetMoves[0];
    SetMovesList[{}];
);

(* Aggiornamento dell'interfaccia grafica *)
aggiornaGrafica[Dynamic[stato_]] := Grid[MapIndexed[
   Button[#1 /. 0 -> "", If[MemberQ[MossePossibili[stato], #2], stato = Muovi[stato, #2]],
      Enabled -> (#1 != 0), ImageSize -> {50, 50}] &, stato, {2}],
  Frame -> All];

(* Interfaccia utente del gioco *)
InterfacciaGioco[] := DynamicModule[{stato, seedInput = "", playerNameInput = "", vittoria = False},
    stato = IniziaGioco[];

    Panel[Column[
        {
        Row[{"Enter player name: ", InputField[Dynamic[playerNameInput], String]}],
        Dynamic[SetPlayerName[playerNameInput]; "Player: " <> GetPlayerName[]],
        Row[{
            "Enter seed: ", InputField[Dynamic[seedInput], Number, ImageSize -> {120, 20}],
            Button["Generate from Seed",
                If[seedInput =!= "" && IntegerQ[seedInput] && playerNameInput =!= "",
                    stato = IniziaGioco[ToExpression[seedInput]];
                    ResetMosse[];
                    vittoria = ControllaVittoria[stato];
                    SalvaConfigurazione[stato, FileNameJoin[{NotebookDirectory[], "gameState.json"}]];
                    If[ConfigurazioneNonSolubile[stato],
                        MessageDialog["The seed does not generate a solvable configuration. Please try another seed."]],
                    MessageDialog["Please enter a valid integer for the seed and a player name."]],
                ImageSize -> {150, 40}
            ]
        }],
        Dynamic[If[seedInput === "" || playerNameInput === "", Style["Please enter both player name and seed to start the game.", Red],
            If[vittoria, Style["Congratulazioni! Hai completato il gioco in " <> ToString[GetMoves[]] <> " mosse.", Bold, Red, 16], aggiornaGrafica[Dynamic[stato]]]]],
        Dynamic[If[seedInput =!= "" && playerNameInput =!= "", Column[{Button["Reset", stato = ResetGioco[ToExpression[seedInput]]; seedInput = ""; SetMoves[0]; vittoria = False, ImageSize -> {100, 40}], mostraSoluzioneButton["soluzione.txt"]}], Nothing]],
        Dynamic["Moves: " <> ToString[GetMoves[]]]
        }]
    ]
];

End[];

EndPackage[];




