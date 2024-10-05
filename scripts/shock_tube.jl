using ShockwaveIdentifier

#1D Case

#Load data
#data_1 = load_data("dataSim/sod_shock_left_1d.tape")
#data_1 = load_data("dataSim/sod_shock_right_1d.tape")


#Find shock points at given frame: findShock1D(frame, data::EulerSim{1, 3, T})
#shockPoints_1 = findShock1D(10, data_1)
#print(shockPoints_1)


#Find shock points at all frames: findAllShocks1D(data::EulerSim{1, 3, T})
#shockPoints_all_1 = findAllShocks1D(data_1)
#print(shockPoints_all_1)


#Plot 1D frame data: plotframe(frame, data::EulerSim{1, 3, T})
#plotframe1D(100, data_1)


#Plott 1D frame data with shocks: plotframe(frame, data::EulerSim{1, 3, T}, shock_algorithm, save = false)
#plotframe1D(100, data_1, findShock1D, true)

#Generate png files for each frame #TODO find gif script: generate_shock_plots1D(data::EulerSim{1, 3, T})
#generate_shock_plots1D(data_1)


#2D Case


#Load Data
data_2 = load_data("dataSim/sod_shock_orb.tape")
#data_2 = load_data("dataSim/sod_shock_right_1d.tape")


#Find shock points at given frame: findShock2D(frame, data::EulerSim{2, 4, T})
#shockPoints_2 = findShock2D(10, data_2)
#print(shockPoints_2)


#Find shock points at all frames: findAllShocks2D(data::EulerSim{2, 4, T})
#shockPoints_all_2 = findAllShocks2D(data_2)
#print(shockPoints_all_2)


#Plot 2D frame data: plotframe2D(frame, data::EulerSim{2, 4, T}, compute_data_function)
#compute_data_function options:
plotframe2D(10, data_2, ShockwaveIdentifier.compute_pressure_data)
plotframe2D(10, data_2, ShockwaveIdentifier.compute_pressure_data, findShock2D)


