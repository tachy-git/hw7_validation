import subprocess
import os

input_file = "LHC.hepmc"
output_file = "filtered.hepmc"
print("Start filtering LHC.hepmc file...")
if not os.path.exists(input_file):
    print("No LHC.hepmc file. exit")
    exit()
if os.path.exists(output_file):
    os.remove(output_file)

command = f"""
python3 -c '
import pyhepmc as hep
import pyhepmc.io as hep_io
reader = hep.open("{input_file}", "r")
writer = hep_io.WriterAsciiHepMC2("{output_file}")
for event in reader:
    zp = [p for p in event.particles if abs(p.pid) == 32]
    if len(zp) > 0:
        writer.write(event)
reader.close()
writer.close()
print("Filtered events saved to {output_file}")
'
"""
result = subprocess.run(command, shell=True, capture_output=True, text=True)
print(result.stdout)
print(result.stderr)

if "ERROR" in result.stdout or "ERROR" in result.stderr:
    print("Error detected. Delete filtered.hepmc.")
    if os.path.exists(output_file):
        os.remove(output_file)
else:
    print(f"Filtered events saved to {output_file}.")

print("Delete LHC.hepmc to free up memory")
if os.path.exists(input_file):
    os.remove(input_file)
