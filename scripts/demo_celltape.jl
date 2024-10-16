using ShockwaveIdentifier

tapes = [
    "../dataSim/funky_triangle.celltape"
    "../dataSim/funky_square.celltape"
    "../dataSim/circular_obstacle_radius_1.celltape"

    ]

for tape in tapes
    println("Processing $tape")
    generate_shock_plots2D(load_data(tape), threshold = 0.2, level=2)
end