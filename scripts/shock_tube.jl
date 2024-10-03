using ShockwaveIdentifier
#Example usage for 1D
#=
#Load data
data = load_sim_data("dataSim/sod_shock_right_1d.tape")

#Find shock points at given frame (10 for example)
shockPoints = findShock1D(10, data)
#print(shockPoints_1)

#Find shock points for all frames
shockPoints_all = findAllShocks1D(data)
#print(shockPoints_1_all)

#Plot 1D frame without shock points
plotframe1D(10, data)

#Plot 1D frame with shock points
plotframe1D(10, data, findShock1D, true)

#Generate png files for each frame #TODO find gif script
generate_shock_plots1D("dataSim/sod_shock_right_1d.tape")
=#

#DATA = load_sim_data("dataSim/sod_shock_left_1d.tape")
#DATA = load_sim_data("dataSim/sod_shock_right_2d.tape")
#DATA = load_sim_data("dataSim/sod_shock_orb.tape")

#shockPoints = findShock2D(100, sod_shock_orb)
#normalVectors(100, sod_shock_orb, shockPoints)
#plotframe2D(100, DATA, ShockwaveIdentifier.compute_pressure_data)
#plotframe2D(100, DATA, ShockwaveIdentifier.compute_pressure_data, findShock2D)



