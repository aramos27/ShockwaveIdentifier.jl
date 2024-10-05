using ShockwaveIdentifier
#Example usage for 1D

#Generate png files for each frame 
#Sod examples
sod_example_tapes = [
    "dataSim/sod_shock_right_1d.tape",
    "dataSim/sod_shock_left_1d.tape"
]

for tape in sod_example_tapes

    generate_shock_plots1D(load_data(tape))
end
#Supersonic shock tapes
supersonic_example_tapes = [
    "../dataSim/supersonic_shock_1.tape"
    "../dataSim/supersonic_shock_2.tape"
    "../dataSim/supersonic_shock_3.tape"
]
for tape in supersonic_example_tapes
    generate_shock_plots1D(load_data(tape))
end






