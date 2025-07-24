# ------------------- CONTEXT -------------------
# Aquest script agafa les dades de sortida de convertirFitxers.py que són del tipus
""" {
      "TIMESTAMP": "2025-05-19 00:02:00",
      "DATE": "2025-05-19",
      "HOUR": "00:02:00",
      "RECORD": 947602,
      "Global_Avg": -5.536,
      "Diffuse_Avg": -7.089,
      "Beam_Avg": -0.508,
      "Global_Std": 0.095,
      "Diffuse_Std": 0,
      "Beam_Std": 0.167,
} """
# Les dades es troben a "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON"
# Prenem per exemple el fitxer '20250526.json' 
# En calcula l'angle zenital solar utilitzant calcular_AZS(lat, lon, data, hora) de calcularAZS.py
# I utilitza la fórmula G = B*cos(AZS) + D per calcular la radiació global G_teo
# tot fent la corresponent propagació d'incerteses $\delta G = \sqrt{(\delta D)^2 +\left[ \cos(AZS) \cdot \delta B \right]^2 + \left[ B \cdot \sin(AZS) \cdot \delta AZS \right]^2}$
# Finalment ho compara amb el valor experimental Global_Avg i dona l'error relatiu entre les mesures

# --------------------- SCRIPT ---------------------

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
input_file = "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON/20250526.json"

# Carreguem el fitxer JSON
with open(input_file, "r") as f:
    dades = json.load(f)

# Per cada mesura, calcularem la radiació global teròrica i farem la comparació
for fila in dades["data"]:

    # ---- TEMPORAL ----
    # if dades["data"].index(fila) > 6800:
    #     exit()
    # # Ens quedem només amb les dades del 23-05-2025
    # if dades["data"].index(fila) in range(0,6300) or dades["data"].index(fila) in range(6305,15000): # 6800
    #     continue
    # ------------------

    # Per tal que es pugui mostrar en la terminal de Windows, mostrem 1 de cada 6 línies
    if (dades["data"].index(fila)+2) % 6 != 0: # +2 perquè coincixeixi amb l'excel de la NOAA
        continue

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
    (cosAZS, dcosAZS) = calcular_cos_AZS(LAT, LON, data, hora)  # dAZS és la incertesa de l'angle
    AZS = math.acos(cosAZS)  # Angle zenital solar
    dAZS = dcosAZS / math.sqrt(1 - cosAZS**2)

    # Calculem la radiació global teòrica (EQUACIÓ PRINCIPAL)
    G_teo = B * math.cos(AZS) + D

    # Propagació d'incerteses
    dG_teo = math.sqrt(
        dD**2 +
        (math.cos(AZS) * dB)**2 +
        (B * math.sin(AZS) * dAZS)**2
    )

    # Errors relatius de cada valor
    e_G_teo = (dG_teo/abs(G_teo))*100 if G_teo != 0 else float('nan') # Evitem divisió per zero
    e_G_exp = (dG_exp/abs(G_exp))*100 if G_exp != 0 else float('nan') # Mateixa bona pràctica
    dG = math.sqrt(dG_teo**2 + dG_exp**2)

    # Mirem quin té menor error relatiu
    if e_G_teo < e_G_exp:
        Glob = G_teo
        dGlob = dG_teo
    else:
        Glob = G_exp
        dGlob = dG_exp

    # Valor mitjà i mínim entre l'experimental i el teòric
    G_mig = (G_teo + G_exp) / 2
    G_min = min(G_teo, G_exp)

    # Ratio entre mesures (per si ho comparem fent servir el ratio)
    ratio = G_exp / G_teo if G_teo != 0 else float('nan')
    dratio = math.sqrt( (dG_exp/G_teo)**2 + (G_exp*dG_teo/G_teo**2)**2 ) if G_teo != 0 else float('nan')

    # Ara calculem la discrepància entre les mesures
    disc = abs(G_teo - G_exp)

    # I també la discrepància relativa
    # disc_rel = disc/G_mig if G_mig != 0 else float('nan')
    disc_rel = disc/Glob if Glob != 0 else float('nan')

    # Mirem si són compatibles
    if disc < 2*dG:
        compatibilitat = 1 # True
    elif disc > 3*dG:
        compatibilitat = 0 # False
    else:
        compatibilitat = -1 # Ni compatibles ni compatibles

    # Mostrarem l'angle d'elevació solar
    elev_sol = 90 - math.degrees(AZS)
    delev_sol = math.degrees(dAZS)

    # --- TEMPORAL ---
    # elev_sol -= 0 # Per provar i comparar amb les dades de l'excel de la NOAA
    # ---------------

    # ---- Criteris de color en l'output ----
    # Ratio
    if abs(ratio-1) <= 0.01:
        ratio_color = Fore.GREEN
    elif 0.01 < abs(ratio-1) <= 0.02:
        ratio_color = Fore.YELLOW
    else:
        ratio_color = Fore.RED
    # Elevació solar
    if elev_sol > 15:
        horitzo = False
        casiHoritzo = False
        elev_color = Fore.GREEN
    elif elev_sol < 10:
        elev_color = Fore.RED
        horitzo = True
        casiHoritzo = False
    else:
        elev_color = Fore.YELLOW
        horitzo = False
        casiHoritzo = True
    # Errors relatius
    if e_G_exp < 2:
        e_color_exp = Fore.GREEN
    elif e_G_exp > 3:
        e_color_exp = Fore.RED
    else:
        e_color_exp = Fore.YELLOW
    if e_G_teo < 2:
        e_color_teo = Fore.GREEN
    elif e_G_teo > 3:
        e_color_teo = Fore.RED
    else:
        e_color_teo = Fore.YELLOW
     # Compatibilitat
    if compatibilitat == 1:
        compat_color = Fore.GREEN
        msg_compat = "Sí"
    elif compatibilitat == 0:
        compat_color = Fore.RED
        msg_compat = "No"
    else:
        compat_color = Fore.YELLOW
        msg_compat = "Ns/Nc"
    # ---------------------------------------


    
    # Mirem també l'estat del cel a aquella hora (núvol, horitzó, etc.)
    rati_difusa = D / (B + D) if (B + D) > 0 else 1.0
    if horitzo:
        msg_estat = "HORITZÓ"
        color_estat = Fore.RED
    elif B < 5 and D < 70 and not casiHoritzo:
        msg_estat = "MOLT ENNUVOLAT"
        color_estat = Fore.RED
    elif (B < 20 and D >= 70) or (rati_difusa > 0.75 and not casiHoritzo):
        msg_estat = "NÚVOL"
        color_estat = Fore.RED
    elif 0.4 <= rati_difusa <= 0.75:
        msg_estat = "UNA MICA ENNUVOLAT"
        color_estat = Fore.YELLOW
    elif rati_difusa < 0.4 and B > 100:
        msg_estat = "CEL CLAR"
        color_estat = Fore.GREEN
    elif casiHoritzo and B < 20 and rati_difusa > 0.6:
        msg_estat = "DIFUSIÓ CONSIDERABLE PERÒ SOL BAIX (Ns/Nc)"
        color_estat = Fore.YELLOW
    else:
        msg_estat = "Ns/Nc"
        color_estat = Fore.YELLOW

    # print("--- RESULTATS ---")
    print(f"Mesura {data} {Fore.CYAN}{hora}{Fore.RESET}")
    print(f"90-AZS: {elev_color + f'{elev_sol:.2f}'} ± {delev_sol:.2f}")
    print(f"Directa: {B:.2f} ± {dB:.2f} ; Difusa: {D:.2f} ± {dD:.2f}")
    print(f"Estat del cel: {color_estat}{msg_estat}{Fore.RESET}")
    print(f"G_exp: {G_exp:.2f} ± {dG_exp:.2f} ; err_rel = {e_color_exp + f'{e_G_exp:.2f}%'}")
    print(f"G_teo: {G_teo:.2f} ± {dG_teo:.2f} ; err_rel = {e_color_teo + f'{e_G_teo:.2f}%'}")
    print(f"Ratio: {ratio_color}{ratio:.3f} ± {dratio:.3f}")
    print(f"Discrepància rel: {disc_rel:.2%} ; Compatibles: {compat_color + msg_compat + Fore.RESET}")
    print("----------------------------------------------")