using ShockwaveIdentifier
# Filename, level and detection threshold. obstacle files shall be tested with level 2.
# Thresholds exist as preset values,
# but may need to be tested for each tape file, for which a δ_1_ρ heatmap can be useful.
tape_data = [
    ("../dataSim/circular_obstacle_radius_1.celltape", 2, 0.2),
    ("../dataSim/funky_square.celltape", 2, 0.2),
    ("../dataSim/funky_triangle.celltape", 2, 0.2),
    ("../dataSim/sod_shock_right_2d.tape", 1, 1.25),
    ("../dataSim/sod_shock_orb.tape", 1, 0.11),
]

for tape in tape_data
    println("Processing $tape")
    generate_shock_plots2D(load_data(tape[1]), vectors=false, level=tape[2], threshold=tape[3])
end
