using ShockwaveIdentifier
#Example usage for 1D

#Load data
#data = load_data("dataSim/supersonic_shock_1.tape")
data = load_data("dataSim/supersonic_shock_2.tape")
#data = load_data("dataSim/supersonic_shock_3.tape)

#Find shock points at given frame (10 for example)
#shockPoints = findShock1D(10, data)
#print(shockPoints)

#Find shock points for all frames
#shockPoints_all = findAllShocks1D(data)
#print(shockPoints_all)

#Plot 1D frame without shock points
plotframe1D(100, data)

#Plot 1D frame with shock points
plotframe1D(100, data, findShock1D, true)

#Generate png files for each frame #TODO find gif script
#generate_shock_plots1D("dataSim/sod_shock_right_1d.tape")
