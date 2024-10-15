using ShockwaveIdentifier
using Plots
using Unitful

tape = "../dataSim/funky_triangle.celltape"
tape2 = "../dataSim/sod_shock_orb.tape"
data = load_data(tape)
data2 = load_data(tape2)

scalarfield = ShockwaveIdentifier.testscalar(100, data2)
field = ShockwaveIdentifier.compute_density_data(100, data2)

field_no_unit = Unitful.ustrip(field)
test = Unitful.ustrip(field_no_unit)



print(scalarfield == field_no_unit)
