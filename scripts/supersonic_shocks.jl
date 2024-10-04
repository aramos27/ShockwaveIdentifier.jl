using ShockwaveIdentifier

"""
Load Data
"""
#data = load_data("dataSim/supersonic_shock_1.tape")
data = load_data("dataSim/supersonic_shock_2.tape")
#data = load_data("dataSim/supersonic_shock_3.tape)

"""
Find shock points at given frame: findShock1D(frame, data::EulerSim{1, 3, T})
"""
#shockPoints = findShock1D(10, data)
#print(shockPoints)

"""
Find shock points at all frames: findAllShocks1D(data::EulerSim{1, 3, T})
"""
#shockPoints_all = findAllShocks1D(data)
#print(shockPoints_all)

"""
Plot 1D frame data: plotframe(frame, data::EulerSim{1, 3, T})
"""
#plotframe1D(100, data)

"""
Plott 1D frame data with shocks: plotframe(frame, data::EulerSim{1, 3, T}, shock_algorithm, save = false)
"""
#plotframe1D(100, data, findShock1D, true)

"""
Generate png files for each frame #TODO find gif script: generate_shock_plots1D(data::EulerSim{1, 3, T})
"""
generate_shock_plots1D(data)


