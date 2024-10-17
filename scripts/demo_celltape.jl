using ShockwaveIdentifier

tape_data = [
    ("../dataSim/circular_obstacle_radius_1.celltape", 2, 0.2),
    ("../dataSim/funky_square.celltape", 2, 0.2),
    ("../dataSim/funky_triangle.celltape", 2, 0.2),
]

for tape in tape_data
    println("Processing $tape")
    generate_shock_plots2D(load_data(tape[1]), vectors=false, level=tape[2], threshold=tape[3])
end