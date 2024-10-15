using ShockwaveIdentifier
using Plots
using Unitful

tape2 = "../dataSim/funky_triangle.celltape"
tape = "../dataSim/sod_shock_right_2d.tape"
frame = 5
data = load_data(tape)
data2 = load_data(tape2)
pressure_field_1_units = ShockwaveIdentifier.testscalar(frame, data2)
pressure_field_1_no_units = [x === nothing ? 0.0 : ustrip(x) for x in pressure_field_1_units]

rows, cols = size(pressure_field_1_no_units)
    
# Step 2: Create a new Float64 matrix for the result with swapped dimensions
rotated = Matrix{Float64}(undef, cols, rows)  
    
#=Step 3: Fill the rotated matrix
for i in 1:rows  # Iterate over the original rows
    for j in 1:cols  # Iterate over the original columns
        rotated[j, rows - i + 1] = pressure_field_1_no_units[i, j]  # Rotate 90 degrees clockwise
    end
end
=#
for i in 1:rows  # Iterate over the original rows
    for j in 1:cols  # Iterate over the original columns
        rotated[cols - j + 1, i] = pressure_field_1_no_units[i, j]  # Rotate 90 degrees counterclockwise
    end
end


println(typeof(pressure_field_1_no_units))
println(typeof(rotated))


ShockwaveIdentifier.plot_1d_heatmap(rotated, "test.png")
fig = ShockwaveIdentifier.plotframe2D_test(frame, data2, findShock2D)
Plots.savefig(fig, "letsgo2.png")