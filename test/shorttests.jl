using ShockwaveIdentifier
using Test

sodleft = load_data("../dataSim/sod_shock_left_1d.tape")
sod_orb = load_data("../dataSim/sod_shock_orb.tape")
triangle = load_data("../dataSim/funky_triangle.celltape")

@test !isempty(findShock1D(42, sodleft)) == true

@test !isempty(findShock2D(42, sod_orb; level = 1)) == true

@test !isempty(findShock2D(4, triangle; level = 1)) == true

