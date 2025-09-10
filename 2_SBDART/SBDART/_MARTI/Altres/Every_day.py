import time
import datetime
import shutil
import os
import urllib.request
import ssl; ssl._create_default_https_context = ssl._create_stdlib_context

from timeloop import Timeloop
from datetime import timedelta

tl = Timeloop()

# @tl.job(interval=timedelta(minutes=1))
# def sample_job_every_2s():
#     print("1m job current time : {}".format(time.ctime()))

# @tl.job(interval=timedelta(minutes=2))
# def sample_job_every_5s():
#     print("2m job current time : {}".format(time.ctime()))

@tl.job(interval=timedelta(seconds=720)) # 12 minutes
def Simulate_UVI():
    today_and_now = datetime.datetime.now()
    print(today_and_now, "Waiting for Total Ozone Column (TOC) forecast at TEMIS")
    hour = time.strftime("%H")
    minute = time.strftime("%M")
    # now = hour + ':' + minute; print(now)
    DOY_today = int(today_and_now.strftime('%j'))
    hour = int(hour)
    minute = int(minute)
    daytime = hour+minute/60
    if (daytime >= 5.5) and (daytime < 5.7): # and (5.5 < daytime < 5.7)
      # UVI FORECAST for today
      # Retrieving TOC (Total Ozone Column) for UVI simulation for today) --> webscrapping at TEMIS
      # Ubicació: De Google Maps: 41.963414901120856, 2.8312717725826033
      datos = urllib.request.urlopen("https://www.temis.nl/uvradiation/nrt/uvindex.php?lon=2.831&lat=41.963").read().decode()
      datos = str(datos); # print(datos)
      # Auxiliar per trobar la posició del valor a la pàgina web: 
      #             position = datos.find(" DU "); # print(position)
      TOC = float((datos[5075:5079]))/1000; print("Total ozone column = ", TOC, " atm cm")
      # EXECUTE UVI SIMULATION - Based on SBDART runs
      os.system('cmd /c "del output.dat"')
      os.system('cmd /c "del UVI_forecast.dat"')
      # ------------   Generate INPUT file
      for i in range(1,241):
        f = open("input", "w")
        hour = (i-1)*0.1
        input = "&input\n"
        input = input + "alat = 41.962\n" + "alon = 2.83\n" + "zpres = 0.115\n"    # Site 
        input = input + "iday = " + str(DOY_today) + "\n" + "time = " + str(hour) + "\n" # Date and time 
        input = input + "idatm = 2\n" + "albcon = 0.065\n"                         # Atmospheric and surface conditions
        input = input + "uo3 = " + str(TOC) + "\n"                                 # TOC forecast for today, from TEMIS
        input = input + "iaer = 1\n" + "tbaer = 0.1\n"                             # Aerosol
        input = input + "wlinf = 0.28\n" + "wlsup = 0.4\n" + "wlinc = 0.001\n"     # Spectral range and resolution
        input = input + "isat = -1\n"                                              # Read filter corresponding to CIE Erythemal Action Spectrum
        input = input + "nstr = 8\n"
        input = input + "zout = 0,100\n" + "iout = 10\n"
        input = input + "&end"
        f.write(input)
        f.close()
        print("DOY: ",DOY_today, "Time: ", hour)
        os.system('cmd /c "sbdart >> output.dat"')
      #------------   Generate UVI_forecast.dat file
      file_in = open('output.dat'); N_lines=len(file_in.readlines()); file_in.close; print(N_lines, " lines in output.dat")
      file_in = open('output.dat')
      file_out = open('UVI_forecast.dat', "w")
      for i in range(1,N_lines+1):
        hour = (i-1)*0.1
        today = time.strftime("%Y") +'-'+ time.strftime("%m") +'-'+ time.strftime("%d")
        HH = int(hour); MM = (hour*60)%60; # MM = round(,0)HHMM = str(HH) + ':' + str(MM); print(HHMM)
        HHMM = ("%d:%02d" % (HH, MM))
        linia = file_in.readline()
        linia = linia.replace("  "," ")
        linia = linia.split(" ")
        UVI = 40*float(linia[13]); UVI = round(UVI,2)
        output = today + ' ' + HHMM + ":00," + str(UVI) + "\n"; print(output)
        file_out.write(output)
      file_in.close   
      file_out.close
      print("UVI_forecast.dat updated")
tl.start()

while True:
  try:
    time.sleep(1)
  except KeyboardInterrupt:
    tl.stop()
    break