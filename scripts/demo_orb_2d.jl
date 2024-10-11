using ShockwaveIdentifier

#Tape file location
tape = "../dataSim/sod_shock_orb.tape"
#import tape file as data object
data = load_data(tape)
println("Processing $tape ")
#Find shock waves and plot them directly in the pre-set folder /frames/date-hours-minutes-seconds
generate_shock_plots2D(data; threshold = 0.2)
