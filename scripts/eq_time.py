from calcularAZS import eq_temps_precisa

for i in range(1, 366):
    EoT = eq_temps_precisa(i)
    print(f"Dia {i}: EoT = {EoT:.2f} minuts")