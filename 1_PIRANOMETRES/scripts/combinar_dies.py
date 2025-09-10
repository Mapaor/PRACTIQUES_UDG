# Script que agafa tots els fitxers .JSON (que son iguals pero de diferents dates) de una carpeta i els combina en un  sol JSON
"""
{
  "metadata": {
    "dataInfo": [
      "TOA5",
      "CR1000",
      "CR1000",
      "1431",
      "CR1000.Std.29",
      "CPU:multipyr_(13-feb-2023).CR1",
      "55357",
      "Table1"
    ],
    "dataUnits": [
      "TS",
      "RN",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV",
      "mV"
    ],
    "dataType": [
      "",
      "",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Avg",
      "Std",
      "Std",
      "Std",
      "Std"
    ],
    "row_count": 10079,
    "valid_count": 10079
  },
  "data": [
    {
      "TIMESTAMP": "2025-05-19 00:02:00",
      "DATE": "2025-05-19",
      "HOUR": "00:02:00",
      "RECORD": 947602,
      "Global_Avg": -5.536,
      "Diffuse_Avg": -7.089,
      "Beam_Avg": -0.508,
      "PYRH_R_Avg": 105.9,
      "UV_volt_Avg": 12.11,
      "TempUV_AVG": 24.98,
      "PYRG_volt_Avg": -1.064,
      "PYRG_R_Avg": 107.3,
      "PPFD_Avg": -0.115,
      "PV1_Avg": -0.874,
      "Global_Std": 0.095,
      "Diffuse_Std": 0,
      "Beam_Std": 0.167,
      "PV1_Std": 0.74
    },
    {
      "TIMESTAMP": "2025-05-19 00:03:00",
      "DATE": "2025-05-19",
      "HOUR": "00:03:00",
      "RECORD": 947603,
      "Global_Avg": -5.806,
      "Diffuse_Avg": -7.288,
      "Beam_Avg": -0.67,
      "PYRH_R_Avg": 105.9,
      "UV_volt_Avg": 12.7,
      "TempUV_AVG": 24.94,
      "PYRG_volt_Avg": -1.056,
      "PYRG_R_Avg": 107.3,
      "PPFD_Avg": -0.058,
      "PV1_Avg": -1.021,
      "Global_Std": 0.117,
      "Diffuse_Std": 0.186,
      "Beam_Std": 0,
      "PV1_Std": 0.883
    },
    // AFEGIR AQUI
"""

input_folder = "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON"
output_file = "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON/combined.json"
import os
import json

# Llista tots els fitxers .json de la carpeta
json_files = [f for f in os.listdir(input_folder) if f.endswith('.json')]

combined_data = []
metadata = None
total_rows = 0

for idx, filename in enumerate(json_files):
    filepath = os.path.join(input_folder, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = json.load(f)
        if idx == 0:
            metadata = content['metadata']
        combined_data.extend(content['data'])
        total_rows += len(content['data'])

# Actualitza row_count i valid_count
if metadata:
    metadata['row_count'] = total_rows
    metadata['valid_count'] = total_rows

# Guarda el fitxer combinat
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump({'metadata': metadata, 'data': combined_data}, f, ensure_ascii=False, indent=2)