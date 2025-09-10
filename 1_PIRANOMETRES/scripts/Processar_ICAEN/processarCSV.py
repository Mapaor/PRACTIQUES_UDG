import csv
import json
from datetime import datetime

input_file = "Processar_ICAEN/ICAEN_Serie_2.csv"
output_file = "Processar_ICAEN/ICAEN_Serie_2.json"

data = []

with open(input_file, encoding="utf-8") as f:
    reader = csv.reader(f, delimiter=';', quotechar='"')
    header = next(reader)
    # Elimina camps buits al final de la capçalera
    header = [h for h in header if h.strip() != '']

    record_num = 1
    for row in reader:
        # Elimina camps buits al final de la fila
        row = [v for v in row if v.strip() != '']
        if not row or len(row) < 2:
            continue

        obj = {}
        timestamp_str = row[0].strip()
        try:
            # Converteix de DD/MM/YYYY HH:MM a YYYY-MM-DD HH:MM:SS
            dt = datetime.strptime(timestamp_str, "%d/%m/%Y %H:%M")
            timestamp_iso = dt.strftime("%Y-%m-%d %H:%M:%S")
            obj["TIMESTAMP"] = timestamp_iso
            obj["DATE"] = dt.strftime("%Y-%m-%d")
            obj["HOUR"] = dt.strftime("%H:%M:%S")
        except Exception as e:
            obj["TIMESTAMP"] = timestamp_str
            obj["DATE"] = None
            obj["HOUR"] = None

        obj["RECORD"] = record_num + 14166
        record_num += 1

        # Afegeix la resta de camps numèrics
        for k, v in zip(header[1:], row[1:]):
            v = v.strip()
            if v == '':
                obj[k] = None
            else:
                try:
                    num = float(v)
                    obj[k] = int(num) if num.is_integer() else num
                except Exception:
                    obj[k] = v  # Si no és numèric, el deixa com a text

        data.append(obj)

# Guarda el JSON
with open(output_file, "w", encoding="utf-8") as f:
    json.dump({"data": data}, f, ensure_ascii=False, indent=2)

print(f"Fitxer JSON generat: {output_file}")