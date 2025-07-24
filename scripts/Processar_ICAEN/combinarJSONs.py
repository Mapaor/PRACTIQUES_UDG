import json

# Noms dels fitxers d'entrada i sortida
fitxer1 = "Processar_ICAEN/ICAEN_Serie_1.json"
fitxer2 = "Processar_ICAEN/ICAEN_Serie_2.json"
fitxer_sortida = "Processar_ICAEN/ICAEN_dades.json"

# Llegeix el primer fitxer
with open(fitxer1, "r", encoding="utf-8") as f1:
    dades1 = json.load(f1)["data"]

# Llegeix el segon fitxer
with open(fitxer2, "r", encoding="utf-8") as f2:
    dades2 = json.load(f2)["data"]

# Combina les dades
dades_combinades = dades1 + dades2

# Guarda el fitxer combinat
with open(fitxer_sortida, "w", encoding="utf-8") as fout:
    json.dump({"data": dades_combinades}, fout, ensure_ascii=False, indent=2)

print(f"Fitxer combinat creat: {fitxer_sortida}")