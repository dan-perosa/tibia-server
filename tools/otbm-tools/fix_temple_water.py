from otbm import read_otbm, write_otbm

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
NEW_TEMPLE = (1030, 1024, 7)  # clean marble floor, no items, verified safe ground type

m = read_otbm(MAP_PATH)
old = m.towns[0]
print(f"Moving town '{old.name}' temple from ({old.x},{old.y},{old.z}) to {NEW_TEMPLE}")
old.x, old.y, old.z = NEW_TEMPLE
write_otbm(m, MAP_PATH)
print("Done!")
