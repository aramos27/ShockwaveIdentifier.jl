using ShockwaveIdentifier

example_tapes = [
    "../dataSim/sod_shock_right_2d.tape"
]

for tape in example_tapes
    println("Processing $tape ")#on thread $(threadid())")
    generate_shock_plots2D(load_data(tape))
end
