import json
import os

# Nom de l'arxiu d'entrada i de sortida
input_file = 'combined.json'
base_name = os.path.splitext(os.path.basename(input_file))[0]
output_file = f"{base_name}_filtrat.json"

# Carrega les dades del fitxer JSON
with open(input_file, 'r', encoding='utf-8') as f:
    dades = json.load(f)

# Afegeix els camps de filtre amb valor null a cada registre dins de "data"
for registre in dades.get('data', []):
    registre['filtreIrradiancia'] = None
    registre['filtreHoritzo'] = None

# Desa el nou fitxer JSON
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(dades, f, indent=2, ensure_ascii=False)

print(f"Fitxer desat amb filtres a: {output_file}")
