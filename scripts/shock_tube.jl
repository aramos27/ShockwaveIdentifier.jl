using ShockwaveIdentifier


#sod_shock_right_1d = load_sim_data("dataSim/sod_shock_right_1d.tape")
#sod_shock_left_1d = load_sim_data("dataSim/sod_shock_left_1d.tape")
#sod_shock_right_2d = load_sim_data("dataSim/sod_shock_right_2d")
sod_shock_orb = load_sim_data("dataSim/sod_shock_orb.tape")

print(findShock2D(100, sod_shock_orb))



