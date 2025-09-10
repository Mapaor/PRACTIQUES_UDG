# El fitxer combined_filtrat.json conté moltes dades
# aprox des del 21-05 fins al 14-07 i per cada dia 1440 registres, és a dir una per minut.
# En canvi el fitxer ICAEN_dades.json conté dades des del 24-06 fins al 18-07, també 1 per cada minut però hi ha "gaps" en què hores senceres no hi ha dades.

# OBJECTIU: Fer un script que agafi els dos JSON i retorni dos JSON "dades_nostres.json" i "dades_icaen.json" que siguin la corresponent filtració
# de manera que sols les dades que estan als dos llocs siguin les que es mantinguin.


# ---- SCRIPT ----

import json

nostres_file = "C:/Users/PC/Documents/_PRACTIQUES_UDG/scripts/combined_filtrat.json"
icaen_file = "C:/Users/PC/Documents/_PRACTIQUES_UDG/scripts/ICAEN_dades.json"

# Llegeix els fitxers
with open(nostres_file, "r", encoding="utf-8") as f:
    nostres_data = json.load(f)["data"]

with open(icaen_file, "r", encoding="utf-8") as f:
    icaen_data = json.load(f)["data"]

# Extreu els timestamps
nostres_timestamps = set(item["TIMESTAMP"] for item in nostres_data)
icaen_timestamps = set(item["TIMESTAMP"] for item in icaen_data)

# Troba la intersecció
timestamps_comuns = nostres_timestamps & icaen_timestamps

# Filtra les dades
nostres_filtrades = [item for item in nostres_data if item["TIMESTAMP"] in timestamps_comuns]
icaen_filtrades = [item for item in icaen_data if item["TIMESTAMP"] in timestamps_comuns]

# Desa els nous fitxers
with open("dades_nostres.json", "w", encoding="utf-8") as f:
    json.dump({"data": nostres_filtrades}, f, ensure_ascii=False, indent=2)

with open("dades_icaen.json", "w", encoding="utf-8") as f:
    json.dump({"data": icaen_filtrades}, f, ensure_ascii=False, indent=2)

print("Nombre de registres ICAEN:", len(icaen_filtrades))
print("Nombre de registres NOSTRES:", len(nostres_filtrades))

from collections import Counter

nostres_counter = Counter(item["TIMESTAMP"] for item in nostres_data)
icaen_counter = Counter(item["TIMESTAMP"] for item in icaen_data)

print("Duplicats NOSTRES:", sum(1 for v in nostres_counter.values() if v > 1))
print("Duplicats ICAEN:", sum(1 for v in icaen_counter.values() if v > 1))

# Mostra els timestamps duplicats a ICAEN
# Mostra els timestamps duplicats a ICAEN
print("Timestamps duplicats a ICAEN:")
for ts, count in icaen_counter.items():
    if count > 1:
        print(ts)
