
from calcularAZS import calcular_cos_AZS, eq_temps_precisa
import math

data="2025-05-23"
hora="09:06:00"
lat=41.964
lon=2.830
cosin_AZS, dummy = calcular_cos_AZS(lat, lon, data, hora)
angle_AZS = math.degrees(math.acos(cosin_AZS))
angle_el = 90 - angle_AZS

import sys
# sys.stdout.reconfigure(encoding='utf-8')
from colorama import Fore, init
init(autoreset=True)


llista_hores = []
for i in range(0, 24):
    for j in range(0, 60, 15):
        if j == 0:
            hora = f"{i:02d}:00:00"
        else:
            hora = f"{i:02d}:{j:02d}:00"
        llista_hores.append(hora)

print(f"EoT 23/05/2025: {eq_temps_precisa(143):.2f} minuts")
for hora in llista_hores:
    cosin_AZS, dummy = calcular_cos_AZS(lat, lon, data, hora)
    angle_AZS = math.degrees(math.acos(cosin_AZS))
    angle_el = 90 - angle_AZS
    print(f"Hora: {Fore.CYAN}{hora}{Fore.RESET}")
    print(f"Angle AZS: {angle_AZS:.2f} graus ; Angle d'elevació: {Fore.GREEN}{angle_el:.2f}{Fore.RESET} graus")