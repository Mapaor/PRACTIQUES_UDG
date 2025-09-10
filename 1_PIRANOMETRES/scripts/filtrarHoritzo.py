import sys
sys.stdout.reconfigure(encoding='utf-8') # Per mostrar bé els accents i caràcters especials

import json
from calcularAZS import calcular_cos_AZS
import math
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

    # Calculem l'angle zenital solar (en radians)
    (cosAZS, dcosAZS) = calcular_cos_AZS(LAT, LON, data, hora)
    AZS = math.acos(cosAZS)
    dAZS = dcosAZS / math.sqrt(1 - cosAZS**2)

    # Mostrarem l'angle d'elevació solar
    elev_sol = 90 - math.degrees(AZS)
    delev_sol = math.degrees(dAZS)

    # Elevació solar
    if elev_sol > 12:
        filtreHoritzo = True # Passa el filtre
        hanPassat += 1
    else:
        filtreHoritzo = False

    # Guardem el resultat del filtre a la fila
    fila["filtreHoritzo"] = filtreHoritzo

# Guardem el fitxer JSON amb la propietat actualitzada
with open(input_file, "w", encoding="utf-8") as f:
    json.dump(dades, f, ensure_ascii=False, indent=2)

print("Dades filtrades correctament.")
print(f"Han passat per horitzo valid: {hanPassat} de {total}")