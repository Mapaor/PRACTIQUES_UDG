# Script que agafa els JSON icaen_bones.json i nostres_filtrades.json
# i afegeix a cada registre (objecte dins de "data") un camp "SERIE" que serà 1 o 2 (de moment).
# Serà 1 per l'interval de dates (data["DATE"]) següent: ("2025-06-18","2025-06-26"). I 2 per l'altre: ("2025-07-02","2025-07-14").
# L'ouput és per tant els mateixos noms de fitxers (actualització)

import json
from datetime import datetime
import os

# L'script s'ha d'executar a la carpeta dadesComparativa (on hi ha l'script i les dades)
workingFolder = os.path.dirname(os.path.abspath(__file__))

fitxerIcaen = os.path.join(workingFolder, "icaen_bones.json")
fitxerNostres = os.path.join(workingFolder, "nostres_filtrades.json")


def assigna_serie(data_str):
    # Defineix els intervals
    if "DATE" not in data_str:
        return None
    date = datetime.strptime(data_str["DATE"], "%Y-%m-%d")
    if datetime(2025, 6, 18) <= date <= datetime(2025, 6, 26):
        return 1
    elif datetime(2025, 7, 2) <= date <= datetime(2025, 7, 14):
        return 2
    else:
        return None

def processa_fitxer(nom_fitxer):
    with open(nom_fitxer, "r", encoding="utf-8") as f:
        dades = json.load(f)
    for registre in dades.get("data", []):
        serie = assigna_serie(registre)
        if serie is not None:
            registre["SERIE"] = serie
    with open(nom_fitxer, "w", encoding="utf-8") as f:
        json.dump(dades, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    processa_fitxer(fitxerIcaen)
    processa_fitxer(fitxerNostres)