import os

def copy_file(src, dst):
    with open(src, 'r') as fsrc, open(dst, 'w') as fdst:
        fdst.write(fsrc.read())

def process_txt_to_dat(input_file, output_file):
    data_lines = []
    header = [
        "WLINF", "WLSUP", "FFEW",
        "TOPDN", "TOPUP", "TOPDIR",
        "BOTDN", "BOTUP", "BOTDIR"
    ]

    with open(input_file, 'r') as f:
        for line in f:
            stripped = line.strip()
            # Ignora línies buides, separadors i capçaleres
            if not stripped:
                continue
            if stripped.startswith('-') or stripped.startswith('WLINF') or stripped.startswith('('):
                continue
            # Si la línia té exactament 9 valors separats per espais, probablement és una línia de dades
            parts = stripped.split()
            if len(parts) == 9:
                # Comprova que tots els valors són números (float)
                try:
                    [float(x.replace('E', 'e')) for x in parts]
                    data_lines.append(parts)
                except ValueError:
                    continue

    # Escriure el fitxer .dat
    with open(output_file, 'w') as f_out:
        f_out.write('# ' + ' '.join(header) + '\n')
        for row in data_lines:
            f_out.write(' '.join(row) + '\n')

def only_important_variables(input_file, output_file):

    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        fout.write('# KT DF\n')
        for line in fin:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) < 9:
                continue  # skip malformed lines
            try:
                EXT = float(parts[3])      # TOPDN
                GLOB = float(parts[6])     # BOTDN
                BOTDIR = float(parts[8])   # BOTDIR
                DIF = GLOB - BOTDIR
                DF = DIF / GLOB if GLOB != 0 else float('nan')
                KT = GLOB / EXT if EXT != 0 else float('nan')
                fout.write(f'{KT:.4f} {DF:.4f}\n')
            except Exception:
                continue

# Directori
folder_path = 'C:\\Users\\PC\\Documents\\_PRACTIQUES_UDG\\2_SBDART\\SBDART\\_MARTI'

# Fitxer generat en la simulació
og_txt_name = "output_data.txt"
original_txt = f'{folder_path}\\_Execucio\\{og_txt_name}'

# Nom que li posem
# ------------------------------------ !!!!!!!!!!!
file_name = "SZA_clouds_NSTR2.txt"
# ------------------------------------ !!!!!!!!!!!

# Variables auxiliars
file_base_name = os.path.splitext(file_name)[0]
input_txt = f'{folder_path}\\Dades\\Originals\\{file_name}'
output_dat = f'{folder_path}\\Dades\\Originals\\{file_base_name}_.dat'
output_filtered_dat = f'{folder_path}\\Dades\\{file_base_name}.dat'

# Executem les funcions
copy_file(original_txt, input_txt)
process_txt_to_dat(input_txt, output_dat)
only_important_variables(output_dat, output_filtered_dat)
