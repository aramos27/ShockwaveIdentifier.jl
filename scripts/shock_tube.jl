using ShockwaveIdentifier


#DATA = load_sim_data("dataSim/sod_shock_right_1d.tape")
#DATA = load_sim_data("dataSim/sod_shock_left_1d.tape")
#DATA = load_sim_data("dataSim/sod_shock_right_2d.tape")
DATA = load_sim_data("dataSim/sod_shock_orb.tape")

#shockPoints = findShock2D(100, sod_shock_orb)
#normalVectors(100, sod_shock_orb, shockPoints)
plotframe2D(100, DATA, ShockwaveIdentifier.compute_pressure_data)
plotframe2D(100, DATA, ShockwaveIdentifier.compute_pressure_data, findShock2D)



