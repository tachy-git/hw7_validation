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
	# filter feynman diagrams
	# modify removeDiag to filter the diags
	# removeDiag = True: only radiated zp
	# removeDiag = False: reverse
	# ===========================================
	removeDiag = True
	zpPid = 9900032

	for p in draw.lineList:
		if p.id != zpPid: continue
		noExternal = True
		for vtx in [p.begin, p.end]:
			for p2 in vtx.lines:
				# 1 Check whether zprime connects to t-channel
				if p2.begin.level==1 and p2.end.level==1:
					return removeDiag

				# 2 Check whether zprime only connects to internal quark line
				# to remove hard scattered Zp connected to s-channel quark
				if not (p2.id)<7: continue
				if len(p2.begin.lines)==1 or len(p2.end.lines)==1:
					noExternal = False

		if noExternal:
			return removeDiag

	return not removeDiag
