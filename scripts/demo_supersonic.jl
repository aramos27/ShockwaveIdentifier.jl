using ShockwaveIdentifier

tapes = [
    "../dataSim/supersonic_shock_1.tape"
]

for tape in tapes
    println("Processing $tape")
    generate_shock_plots1D(load_data(tape))
end

