import pyhepmc as hep
import pyhepmc.io as hep_io
import math

input_file = "LHC.hepmc"
output_file = "LHC_filter.hepmc"

reader = hep.open(input_file, "r")
writer = hep_io.WriterAsciiHepMC2(output_file)

PT_CUT = 30.0  # GeV

def pt(m):
    return math.sqrt(m.px**2 + m.py**2)

for event in reader:
    keep_event = False

    for p in event.particles:
        if abs(p.pid) == 13 and pt(p.momentum) > PT_CUT:
            keep_event = True
            break

    if keep_event:
        writer.write(event)

reader.close()
writer.close()

print(f"Filtered events saved to {output_file}")
