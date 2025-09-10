import sys
sys.stdout.reconfigure(encoding='utf-8') # Per mostrar bé els accents i caràcters especials

import json
from colorama import Fore, init
init(autoreset=True) # Inicialitzem colorama


# Coordenades del departament de Física (Girona)
LAT = 41.964
LON = 2.830

# Nom del fitxer JSON
input_file = "C:/Users/PC/Documents/_PRACTIQUES_UDG/scripts/combined_filtrat.json"

# Carreguem el fitxer JSON
with open(input_file, "r") as f:
    dades = json.load(f)

hanPassat = 0
total = len(dades["data"])

# Per cada mesura, calcularem la radiació global teròrica i farem la comparació
for fila in dades["data"]:
    # Primer obtenim les dades que ens interessen
    data = fila["DATE"]
    hora = fila["HOUR"]
    B = fila["Beam_Avg"]
    D = fila["Diffuse_Avg"]
    G_exp = fila["Global_Avg"]
    dB = fila["Beam_Std"]
    dD = fila["Diffuse_Std"]
    dG_exp = fila["Global_Std"]


    # Filtre per irradiància
    if B < 10.0 or D < 10.0 or G_exp < 10.0:
        filtreIrradiancia = False
        hanPassat += 1
    else:
        filtreIrradiancia = True

    # Guardem el resultat del filtre a la fila
    fila["filtreIrradiancia"] = filtreIrradiancia

# Guardem el fitxer JSON amb la propietat actualitzada
with open(input_file, "w", encoding="utf-8") as f:
    json.dump(dades, f, ensure_ascii=False, indent=2)

print("Dades filtrades correctament.")
print(f"Han passat per irradiància valid: {hanPassat} de {total}")