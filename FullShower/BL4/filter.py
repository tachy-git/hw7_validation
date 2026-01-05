import pyhepmc as hep
import pyhepmc.io as hep_io
import math

input_file = "LHC.hepmc"
output_file = "LHC_filter.hepmc"

reader = hep.open(input_file, "r")
writer = hep_io.WriterAsciiHepMC2(output_file)

PT_CUT_1 = 4.0   # GeV - first muon
PT_CUT_2 = 0.1   # GeV - second muon
DR_CUT = 1.0     # deltaR between muons

def pt(m):
    return math.sqrt(m.px**2 + m.py**2)

def eta(m):
    p = math.sqrt(m.px**2 + m.py**2 + m.pz**2)
    if p == 0:
        return 0
    return math.atanh(m.pz / p)
    # arctanh(p_L/|p|)

def phi(m):
    return math.atan2(m.py, m.px)

def delta_r(m1, m2):
    deta = eta(m1.momentum) - eta(m2.momentum)
    dphi = phi(m1.momentum) - phi(m2.momentum)
    
    while dphi > math.pi:
        dphi -= 2 * math.pi
    while dphi < -math.pi:
        dphi += 2 * math.pi
    
    return math.sqrt(deta**2 + dphi**2)

for event in reader:
    muons = [p for p in event.particles if abs(p.pid) == 13]
    
    if len(muons) < 2:
        continue
    
    keep_event = False
    
    # Check pairs of muons for pT and dR requirements
    for i, mu1 in enumerate(muons):
        for mu2 in muons[i+1:]:
            pt1 = pt(mu1.momentum)
            pt2 = pt(mu2.momentum)
            
            # At least one muon > 4 GeV and both > 0.1 GeV
            if ((pt1 > PT_CUT_1 and pt2 > PT_CUT_2) or 
                (pt2 > PT_CUT_1 and pt1 > PT_CUT_2)):
                
                # Check deltaR
                if delta_r(mu1, mu2) < DR_CUT:
                    keep_event = True
                    break
        
        if keep_event:
            break
    
    if keep_event:
        writer.write(event)

reader.close()
writer.close()

print(f"Filtered events saved to {output_file}")
