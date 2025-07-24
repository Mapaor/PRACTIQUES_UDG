import sys
sys.stdout.reconfigure(encoding='utf-8') # Per mostrar bé els accents i caràcters especials

import csv
import json
import os

from datetime import datetime

# NOM INPUT FILE (.txt, .csv, .MPY...)
# El primer és per si s'executa des de convertirFitxers.py i el segon per si s'executa manualment.
input_file = os.environ.get('input_file', "20250623.MPY")

# Directori de sortida (manualment serà el mateix que l'script i les dades, amb convertirFitxers.py serà el definit a OUT_DIR)
out_directory = os.environ.get('out_directory', '')

# Output file amb el mateix nom però .json enlloc de .txt o .csv o .mpy
base_name = os.path.splitext(os.path.basename(input_file))[0]
if out_directory:
    output_file = os.path.join(out_directory, f"{base_name}.json")
else:
    output_file = f"{base_name}.json"

# Inicialitzem variables
data = []
metadata = {}
row_count = 0
valid_count = 0

# Obrim el fitxer per llegir les dades
with open(input_file, encoding="utf-8") as f:
    
    # Triem ',' com a delimitador
    reader = csv.reader(f, delimiter=',', quotechar='"')

    # Saltem la línia 1 (metadades)
    metadata["dataInfo"] = next(reader)

    # Llegim la línia 2 (capçalera)
    header = [h.strip().replace('"', '') for h in next(reader)]
    print(f"Capçalera: {header}")

    # Saltem les línies 3 i 4 (metadades)
    metadata["dataUnits"] = next(reader)
    metadata["dataType"] = next(reader)
    
    # Ara llegim les dades
    for row in reader:
        row_count += 1

        # Si les dades són buides o no es corresponen a la capçalera les ignorem i avisem de l'error
        if not row or len(row) < len(header):
            print(f"Error: Fila buida o incompleta, es descarta.")
            continue

        # Cada fila serà un objecte JSON. El JSON final serà un array d'aquests objectes.
        obj = {}

        # Si no hi hagués "RECORD", es mostra error i es descarta la fila
        if not row[header.index("RECORD")].strip():
            print(f"Error: Falta RECORD, es descarta.")
            continue

        # Ara anem a actualitzar els objectes (de moment '{}') corresponents a cada fila
        try:
            # En principi el TIMESTAMP és l'únic string

            timestamp_str = row[0].strip().replace('"', '')
            obj[header[0]] = timestamp_str

            # Afegim DATE i HOUR (camps addicionals) a partir del TIMESTAMP
            try:
                dt = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
                obj["DATE"] = dt.strftime("%Y-%m-%d")
                obj["HOUR"] = dt.strftime("%H:%M:%S")
            except Exception as e:
                obj["DATE"] = None
                obj["HOUR"] = None

            # I la resta són números (els convertim a float o int)
            for k, v in zip(header[1:], row[1:]):
                v = v.strip().replace('"', '')
                if v == '':
                    obj[k] = None
                else:
                    num = float(v)
                    obj[k] = int(num) if num.is_integer() else num
        except Exception as e:
            print(f"Error: no s'ha pogut processar la fila: {e}. Es descarta.")
            continue
        data.append(obj)
        valid_count += 1

metadata["row_count"] = row_count
metadata["valid_count"] = valid_count

print(f"Total files llegides: {row_count}")
print(f"Total files valides: {valid_count}")

# Guardem les dades en el fitxer JSON
with open(output_file, "w", encoding="utf-8") as f:
    json.dump({"metadata": metadata,"data": data}, f, ensure_ascii=False, indent=2)

print(f"Fitxer JSON generat: {output_file}")