using ShockwaveIdentifier
using Test

sodleft = load_data("../dataSim/sod_shock_left_1d.tape")
sod_orb = load_data("../dataSim/sod_shock_orb.tape")
triangle = load_data("../dataSim/funky_triangle.celltape")

@test plotframe1D(42, sodleft, findShock1D) 

@test plotframe2D(42, sod_orb, findShock2D; level = 1) 

@test plotframe2D(42, triangle, findShock2D; level = 2)

