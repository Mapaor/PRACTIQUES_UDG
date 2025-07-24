# Script que donada una data "2025-06-18" genera un JSON amb les dades de sols aquell dia
# Agafa el ICAEN_dades.json i retorna 2025-06-18.json
# Maté la mateixa estructura que el fitxer original

import json
from datetime import datetime
import sys
sys.stdout.reconfigure(encoding='utf-8')  # Per mostrar bé els accents i caràcters especials

input_data = "2025-07-06"

input_fila = "C:/Users/PC/Documents/_PRACTIQUES_UDG/scripts/Processar_ICAEN/ICAEN_dades.json"
output_file = f"C:/Users/PC/Documents/_PRACTIQUES_UDG/scripts/diesIcaen/ICAEN_{input_data}.json"

with open(input_fila, "r", encoding="utf-8") as f:
    data = json.load(f)

# Filtrar les dades per la data especificada
data_filtrada = {
    "data": [d for d in data["data"] if d["DATE"] == input_data]
}

# Escriure el JSON filtrat a un nou fitxer
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(data_filtrada, f, ensure_ascii=False, indent=2)

print(f"Fitxer JSON generat: {output_file}")
print(f"Total de registres per {input_data}: {len(data_filtrada['data'])}")