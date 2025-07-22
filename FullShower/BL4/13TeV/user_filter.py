import madgraph.core.drawing as drawing

def remove_diag(diag, model):

	draw = drawing.FeynmanDiagram(diag, model)
	draw.load_diagram()
	#print(draw._debug_load_diagram())
	draw.define_level()

	# ===========================================
	# DO NOT MODIFY THIS PART
	# THIS PART IS FOR THE SUBPROCESS WITH DIMUON
	# ===========================================
	for p in draw.lineList:
		if abs(p.id) == 13:
			return False

	# ===========================================
	# Filter feynman diagrams in p p > j j zp process
	# Please modify 'flagType' to among FSR/ ISR/ FSN
	# FSRLike:	Z' is radiated from the outgoing quark
	# 			Z' line is not connected to T-channel line
	#			and connected to one external quark line
	# ISRLike:	Diagram looks like that Z' is from the incoming quark
	# FSNLike:	Diagram looks like a trident(?) with Z' in the middle
	# 			Z' is connected to two T-channel quarks line
	# ===========================================
	zpPid = 9900032
	flagType = "FSR" # FSR/ ISR/ FSN
	diagType = None

	for p in draw.lineList:
		if p.id != zpPid: continue
		nTchannel = 0
		nExternal = 0
		for vtx in [p.begin, p.end]:
			for p2 in vtx.lines:
				if p2.begin.level==1 and p2.end.level==1:
					nTchannel += 1
				if not (p2.id)<7: continue
				if len(p2.begin.lines)==1 or len(p2.end.lines)==1:
					nExternal += 1

		if nExternal == 1 and nTchannel == 0:
			diagType = "FSR"
		elif nTchannel == 2:
			diagType = "FSN"
		else:
			diagType = "ISR"

	return flagType != diagType
