# Filtrem les dades que encara no tenien el barrat posat.
# 12/06 -  17/06 --> DOLENTES
# 18/06 -  26/06 --> BONES
# 27/06 -  01/07 --> DOLENTES
# 02/07 -  14/07 --> BONES

import json
from datetime import datetime
import os

# Defineix els intervals de dies bones
intervals_bons = [
    ("2025-06-18", "2025-06-26"),
    ("2025-07-02", "2025-07-14"),
]

# Carpeta on hi ha les dades i l'script
workingFolder = os.path.dirname(os.path.abspath(__file__))

def es_data_bona(data_str):
    data = datetime.strptime(data_str, "%Y-%m-%d")
    for start, end in intervals_bons:
        if datetime.strptime(start, "%Y-%m-%d") <= data <= datetime.strptime(end, "%Y-%m-%d"):
            return True
    return False

# Llegeix els fitxers
with open(os.path.join(workingFolder, "dades_icaen.json"), "r", encoding="utf-8") as f:
    icaen = json.load(f)["data"]

with open(os.path.join(workingFolder, "dades_nostres.json"), "r", encoding="utf-8") as f:
    nostres = json.load(f)["data"]

# Filtra per dates bones
icaen_bones = [item for item in icaen if es_data_bona(item["DATE"])]
nostres_filtrades = [item for item in nostres if es_data_bona(item["DATE"])]

# Desa els nous fitxers
with open(os.path.join(workingFolder, "icaen_bones.json"), "w", encoding="utf-8") as f:
    json.dump({"data": icaen_bones}, f, ensure_ascii=False, indent=2)

with open(os.path.join(workingFolder, "nostres_filtrades.json"), "w", encoding="utf-8") as f:
    json.dump({"data": nostres_filtrades}, f, ensure_ascii=False, indent=2)

print("Nombre de registres ICAEN:", len(icaen_bones))
print("Nombre de registres NOSTRES:", len(nostres_filtrades))