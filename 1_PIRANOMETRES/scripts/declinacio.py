import math
from datetime import datetime

def calcularDecl(data, hora):
    dt = datetime.strptime(f"{data} {hora}", "%Y-%m-%d %H:%M:%S")
    fraccio_dia = (dt.hour + dt.minute / 60 + dt.second / 3600) / 24
    JD = dt.toordinal() + 1721424.5 + fraccio_dia
    n = JD - 2451545.0  # Dia Julià - J2000.0
    T = n / 36525.0  # Segles des de J2000.0

    g = 357.52911 + 35999.05029*T - 0.0001537*T**2  # Anomalia mitjana en graus
    g = g % 360
    g_rad = math.radians(g)
    L =  280.46646 + 36000.76983*T  + 0.0003032*T**2  # Longitud mitjana en graus
    L = L % 360
    C = (1.914602 - 0.004817*T - 0.000014*T**2)*math.sin(g_rad) + (0.019993 - 0.000101*T)*math.sin(2*g_rad) + 0.000289*math.sin(3*g_rad)  # Eq. Centre del Sol
    lambd = L + C  # Longitud eclíptica en graus
    lambd = lambd % 360 
    epsilon = 23.436 # Obliqüitat de l'eclíptica en graus | TEMPORAL (valor fixe per comprovar)

    delta = math.asin(math.sin(math.radians(epsilon)) * math.sin(math.radians(lambd)))
    delta_deg = math.degrees(delta)
    return delta_deg

def calcularDecl_IQBAL(data,hora):
    dt = datetime.strptime(f"{data} {hora}", "%Y-%m-%d %H:%M:%S")
    fraccio_dia = (dt.hour + dt.minute / 60 + dt.second / 3600) / 24
    # JD = dt.toordinal() + 1721424.5 + fraccio_dia
    dia_julia = dt.timetuple().tm_yday
    Gamma = 2*math.pi*dia_julia/365
    delta = 0.006918 - 0.399912*math.cos(Gamma) + 0.070257*math.sin(Gamma) - 0.006758*math.cos(2*Gamma) + 0.000907*math.sin(2*Gamma) - 0.002697*math.cos(3*Gamma) + 0.00148*math.sin(3*Gamma)
    delta_deg = math.degrees(delta)
    return delta_deg

# print("Càlcul de la declinació solar:")
data = "2025-05-23"
hora = "12:00:00"
# declinacio = calcularDecl(data, hora)
# print(f"Declinació (mètode 1): {declinacio} graus")
# declinacio_iqbal = calcularDecl_IQBAL(data, hora)
# print(f"Declinació (mètode 2): {declinacio_iqbal} graus")

llista_hores = []
for i in range(0, 24):
    for j in range(0, 60, 15):
        if j == 0:
            hora = f"{i:02d}:00:00"
        else:
            hora = f"{i:02d}:{j:02d}:00"
        llista_hores.append(hora)

import sys
sys.stdout.reconfigure(encoding='utf-8')

print(f"23/05/2025")
for hora in llista_hores:
    declinacio = calcularDecl(data, hora)
    declinacio_iqbal = calcularDecl_IQBAL(data, hora)
    print(f"Hora: {hora}")
    print(f"Martí: {declinacio:.3f} | IQBAL: {declinacio_iqbal:.3f} | Discepància: {declinacio - declinacio_iqbal:.3f} graus")