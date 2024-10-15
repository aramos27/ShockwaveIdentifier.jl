using ShockwaveIdentifier
using Base.Threads

# Example usage for 1D
example_tapes = [
    # Sod examples
    "../dataSim/sod_shock_left_1d.tape",
    "../dataSim/sod_shock_right_1d.tape",
    # Supersonic shock tapes 
    
    "../dataSim/supersonic_shock_1.tape",
    "../dataSim/supersonic_shock_2.tape",
    "../dataSim/supersonic_shock_3.tape" 
    
]

for tape in example_tapes
    println("Processing $tape on thread $(threadid())")
    generate_shock_plots1D(load_data(tape))
end
