import os
import subprocess

# Fitxer de sortida
output_file = "output_data.txt"

# Elimina el fitxer anterior si existeix
if os.path.exists(output_file):
    os.remove(output_file)

# Llistes de valors
sza_vals = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85]

# Escrivim la capçalera
with open(output_file, "a") as out_f:
    out_f.write(f"-------------------------------------------  SZA (0, 90, 5)  ---------------------------------------------\n")
    out_f.write('\u0009WLINF\u0009WLSUP\u0009FFEW\u0009\u0009TOPDN\u0009\u0009TOPUP\u0009TOPDIR\u0009\u0009BOTDN\u0009BOTUP\u0009BOTDIR\n')
    out_f.write('\u0009(μm)\u0009\u0009(μm)\u0009\u0009(μm)\u0009\u0009(W/m²)\u0009\u0009(W/m²)\u0009(W/m²)\u0009\u0009(W/m²)\u0009(W/m²)\u0009(W/m²)\n')
    out_f.write(f"----------------------------------------------------------------------------------------------------------\n")

for sza in sza_vals:
    input_str = f"""
&INPUT
! --- INPUT (ZSA) ---
SZA={sza}
! --- CONFIGURACIÓ ESPECTRAL ---
WLINF = 0.28
WLSUP = 4.0
WLINC = -0.01
! --- ATMOSFERA ---
IDATM = 2       ! Mid-latitude summer
ISALB = 0       ! Albedo uniforme
ALBCON = 0.15   ! Albedo de la superfície
! --- NÚVOLS ---
ZCLOUD = 4.0     ! Altura (km)
TCLOUD = 0.2    ! Gruix òptic 
NRE = 8.0      ! Radi efectiu
! CLDFRAC = 0.35   ! Fracció de núvols
IMOMC = 5            ! Fase de dispersió (Henyey-Greenstein)
! --- AEROSOLS ---
!IAER = 4             ! Tipus (rural, urba, oceànic, troposfèric)
!TBAER = 0.2           ! Opacitat a 0.55um
! --- OUTPUT ---
IOUT = 10       ! Irradiància
ZOUT = 0, 100   ! Superfície i dalt l'atmosfera
NSTR = 8       ! Número d'streams
! --- ALTRES ---
ISAT = 0       ! Sense filtratge
NOTHRM = 1     ! Sense incloure l'emissió tèrmica
! IDB(5) = 0    ! 0 per defecte (escriure a stdout) | IDB(5)=2 per detalls dels núvols
/

"""
    # Escriu l'arxiu INPUT
    with open("INPUT", "w") as f:
        f.write(input_str)

    # Executa sbdart i envia stdout al fitxer de sortida
    with open(output_file, "a") as out_f:
        subprocess.run(["./sbdart"], stdout=out_f)

with open(output_file, "a") as out_f:
      out_f.write(f"----------------------------------------------------------------------------------------------------------\n")
