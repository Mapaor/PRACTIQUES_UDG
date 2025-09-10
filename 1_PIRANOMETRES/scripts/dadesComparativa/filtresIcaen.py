# Aquest script agafa dos JSON icaen_bones.json i nostres_filtrades.json
# els fitxers de dades tenen el mateix nombre de registres dins de l'array "data"
# corresponents a una mesura per minut
# Exemple nostres_filtrades.json:
"""
{
  "data": [
    {
      "TIMESTAMP": "2025-06-18 00:00:00",
      "DATE": "2025-06-18",
      "HOUR": "00:00:00",
      "RECORD": 990800,
      "Global_Avg": -2.065,
      "Diffuse_Avg": -8.52,
      "Beam_Avg": -0.508,
      "PYRH_R_Avg": 107.5,
      "UV_volt_Avg": 11,
      "TempUV_AVG": 24.63,
      "PYRG_volt_Avg": -1.056,
      "PYRG_R_Avg": 109,
      "PPFD_Avg": 0,
      "PV1_Avg": -0.441,
      "Global_Std": 0,
      "Diffuse_Std": 0.139,
      "Beam_Std": 0.167,
      "PV1_Std": 0,
      "filtreIrradiancia": false,
      "filtreHoritzo": false,
      "SERIE": 1
    },
    // Més dades
    ]
}
"""
# Exemple icaen_bones.json:
"""
{
  "data": [
    {
      "TIMESTAMP": "2025-06-18 00:00:00",
      "DATE": "2025-06-18",
      "HOUR": "00:00:00",
      "RECORD": 6633,
      "PYR1": -0.007,
      "PYR2": -0.006,
      "PYR3": -0.007,
      "PYR4": -0.013,
      "PYR5": -0.011,
      "PYR6": -0.013,
      "SERIE": 1
    },
    // Més dades
    ]
}
"""
# OBJECTIU: Afegir a cada registre de icaen_bones.json els filtres `filtreIrradiancia` i `filtreHoritzo` 
# amb els mateixos valors que el corresponent registre de nostre_filtrades.json

# Nota: tant els dos fitxers de dades com el script es troben en la mateixa carpeta

# Output: una modificació (actualització) del fitxer icaen_bones.json afegint els dos camps `filtreIrradiancia` i `filtreHoritzo`.

import json
import os

workingFolder = os.path.dirname(os.path.abspath(__file__))

icaen_path = os.path.join(workingFolder, "icaen_bones.json")
nostres_path = os.path.join(workingFolder, "nostres_filtrades.json")

# Carrega els fitxers JSON
with open(icaen_path, "r", encoding="utf-8") as f:
    icaen_data = json.load(f)

with open(nostres_path, "r", encoding="utf-8") as f:
    nostres_data = json.load(f)

# Assumeix que l'ordre dels registres és el mateix
for i, registre in enumerate(icaen_data["data"]):
    registre["filtreIrradiancia"] = nostres_data["data"][i]["filtreIrradiancia"]
    registre["filtreHoritzo"] = nostres_data["data"][i]["filtreHoritzo"]

# Guarda el fitxer actualitzat
with open(icaen_path, "w", encoding="utf-8") as f:
    json.dump(icaen_data, f, ensure_ascii=False, indent=2)

print("icaen_bones.json actualitzat amb els filtres.")
