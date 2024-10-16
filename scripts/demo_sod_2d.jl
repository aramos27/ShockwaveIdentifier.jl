using ShockwaveIdentifier

#Tape file location
tape = "../dataSim/sod_shock_right_2d.tape"
#import tape file as data object
data = load_data(tape)
println("Processing $tape ")
    println("Processing $tape ")#on thread $(threadid())")
    generate_shock_plots2D(data, vectors=true, level=1, threshold = 1.25)

