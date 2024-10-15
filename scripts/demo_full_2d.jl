using ShockwaveIdentifier
using Base.Threads

# Example usage for 1D
example_tapes = [
    "../dataSim/sod_shock_right_2d.tape"
    "../dataSim/circular_obstacle_radius_1.celltape"
    "../dataSim/funky_square.celltape"
    "../dataSim/funky_triangle.celltape"
    "../dataSim/sod_shock_orb.tape"
]

for tape in example_tapes
    println("Processing $tape on thread $(threadid())")
    generate_shock_plots2D(load_data(tape))
end
