import math
from datetime import datetime

def eq_temps(dia):
    # Manera pràctica simplificada
    if dia not in range(1, 366): raise ValueError("El dia ha de ser entre 1 i 365")
    B_graus = (360/365)*(dia-81)
    B = (math.pi/180)*B_graus
    EOT = 9.87*math.sin(2*B)-7.53*math.cos(B)-1.5*math.sin(B)
    return EOT

def eq_temps_precisa(dia):
    # Manera precisa de la NOAA. Fractional year (gamma) and sum of sine functions.
    if dia not in range(1, 366): raise ValueError("El dia ha de ser entre 1 i 365")
    gamma = (2*math.pi/365)*(dia-1)
    EOT = 229.18*(0.000075 + 0.001868*math.cos(gamma) - 0.032077*math.sin(gamma) - 0.014615*math.cos(2*gamma) - 0.040849*math.sin(2*gamma))
    return EOT

def calcular_cos_AZS(lat, lon, data, hora):
    
    # ----------------------------------- PROCÉS PER TROBAR AZS --------------------------------------------
    # Nota: sempre que diem 'hora' ens referim a 'hora UCT' (i en format decimal)
    # (1) Amb la data i l'hora obtenim el Julian Date (JD) --> Amb JD obtenim n
    #  --> amb n obtenim g, L i epsilon --> amb aquestes 3 obtenim la declinació solar (delta)
    # (2) [OPCIONAL] Amb la data obtenim el dia julià (1-365) i a partir d'aquest l'equació del temps (EoT)
    # es pot fer de manera habitual (eq_temps) o de manera més precisa (eq_temps_precisa). Nosaltres farem servir la precisa
    # (3) Amb l'hora i la longitud obtenim una hora solar local no corregida, si volem
    # li podem afegir EoT/60 per obtenir una hora solar local més precisa.
    # A partir de l'hora solar local obtenim l'angle horari local (h).
    # (4) A partir de la declinació solar (delta), l'angle horari (h) i la latitud en radians calculem cos(AZS)
    # -------------------------------------------------------------------------------------------------------

    # (1)
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

    # (2)
    dia_julia = dt.timetuple().tm_yday
    EoT = eq_temps_precisa(dia_julia)

    # (3)
    horaUCT = dt.hour + dt.minute / 60 + dt.second / 3600
    hora_solar = horaUCT + lon/15 + EoT/60 # hora solar local
    h = 15 * (hora_solar - 12) # angle horari en graus

    # (4)
    lat_rad = math.radians(lat)
    phi = lat_rad
    h_rad = math.radians(h)
    cos_AZS = math.sin(lat_rad) * math.sin(delta) + math.cos(lat_rad) * math.cos(delta) * math.cos(h_rad)

    # Anem a veure quins valors tenim
    # print("-- PREVI: CÀLCUL AZS --")
    # print(f"JD: {JD:.2f}")
    # print(f"n: {n:.2f}")
    # print(f"Mean longitude (L): {L:.2f}")
    # print(f"Mean Anomaly (g): {g:.2f}")
    # print(f"lambda: {lambd:.2f}")
    # print(f"Obliquity (epsilon): {epsilon:.2f}")
    # print(f"Solar declination (delta): {delta_deg:.2f}")
    # print(f"Equation of Time (EoT): {EoT:.2f} minutes")
    # print(f"Latitude (phi): {math.degrees(lat_rad):.2f}")
    # print(f"Longitude (lon): {lon:.2f}")
    # print(f"LST: {hora_solar:.2f} hours")
    # print(f"Hour angle: {h:.2f}")

    # Ara anem a fer la corresponent propagacio d'incerteses
    # ddata = 0
    # dhora = 0
    dlat = math.radians(0.001)
    dlon = 0.001
    dEoT = 0.5 # minuts
    dLST = dlon/15 + dEoT/60
    dh = math.radians(15*dLST) # hauria de donar uns 0.0002 graus
    ddelta = math.radians(0.001) # graus

    """
    $$
    \delta(\cos AZS)
    =
    \sqrt{\Bigl[
    (\cos\Phi\,\sin\delta-\sin\Phi\,\cos\delta\,\cos h)\,\delta\Phi\Bigr]^{2}
    +\Bigl[(\sin\Phi\,\cos\delta-\cos\Phi\,\sin\delta\,\cos h)\,\delta\delta\Bigr]^{2}
    +\Bigl[(-\cos\Phi\,\cos\delta\,\sin h)\,\delta h\Bigr]^{2}
    }
    $$
    """
    dphi = dlat
    dcos_AZS = math.sqrt(
        ((math.cos(phi) * math.sin(delta) - math.sin(phi) * math.cos(delta) * math.cos(h_rad))*dphi)**2 +
        ((math.sin(phi) * math.cos(delta) - math.cos(phi) * math.sin(delta) * math.cos(h_rad))*ddelta)**2 +
        (-math.cos(phi) * math.cos(delta) * math.sin(h_rad)*dh)**2
    )

    return cos_AZS, dcos_AZS
