import os
import subprocess
import sys

# Indica el directori de dades, o deixa-ho en blanc ("") per usar el directori de l'script
DATA_DIR = "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_GFA"  # Exemple: "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_GFA"
# Indica el directori de sortida, o deixa-ho en blanc ("") per usar el mateix que DATA_DIR
OUT_DIR = "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON"  # Exemple: "C:/Users/PC/Documents/_PRACTIQUES_UDG/DADES_JSON"



# Si DATA_DIR està buit, utilitza el directori on es troba aquest script
if DATA_DIR:
    directory = os.path.abspath(DATA_DIR)
else:
    directory = os.path.dirname(os.path.abspath(__file__))

# Si OUT_DIR està buit, utilitza el mateix directori que DATA_DIR
if OUT_DIR:
    out_directory = os.path.abspath(OUT_DIR)
else:
    out_directory = directory

if not os.path.isdir(directory):
    print(f"Directori no trobat: {directory}")
    sys.exit(1)
if not os.path.isdir(out_directory):
    print(f"Directori de sortida no trobat: {out_directory}")
    sys.exit(1)

# Canviem el directori de treball perquè la sortida es generi al lloc correcte
os.chdir(out_directory)

# Obtenim una llista de tots els fitxers amb extensió .MPY
mpy_files = [f for f in os.listdir(directory) if f.lower().endswith('.mpy')]

if not mpy_files:
    print("No s'han trobat fitxers .MPY al directori.")
else:
    print(f"Fitxers .MPY trobats: {mpy_files}")
    for mpy_file in mpy_files:
        print(f"Processant {mpy_file}...")
        input_file_path = os.path.join(directory, mpy_file)
        # Executarem l'script convertirDades.py per cada fitxer .MPY
        subprocess.run([
            sys.executable,
            os.path.join(os.path.dirname(os.path.abspath(__file__)), 'convertirDades.py'),
        ], env={**os.environ, 'input_file': input_file_path, 'directory': directory, 'out_directory': out_directory})
    print("Conversio finalitzada.")
