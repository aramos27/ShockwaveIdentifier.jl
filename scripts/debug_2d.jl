save_dir = "frames"
html = true

using Euler2D
using LaTeXStrings
using LinearAlgebra
using Plots
using Printf
using ShockwaveProperties
using Tullio
using Unitful
using Dates
using Images

using StaticArrays

using ShockwaveIdentifier

data = load_data("../dataSim/funky_triangle.celltape")

@info "Generating shock plots in 2D"

# Generate the current date and time in the desired format
datestr = Dates.format(now(), "mm-dd-HH-MM-SS")

# Create general output directory if it doesn't exist
if !isdir(save_dir)
    mkdir(save_dir)
end
# Create time-stamped directory if outputting to frames folder
if save_dir == "frames"
    save_dir = "frames/$datestr"
end
if !isdir(save_dir)
    mkdir(save_dir)
end

for step in 1:data.nsteps

    final_plot_layout = plotframe2D(step,data,ShockwaveIdentifier.compute_density_data,ShockwaveIdentifier.findShock2D; vectors=false, threshold = ShockwaveIdentifier.eps1_cell, level = 1)

    d1p_plot = ShockwaveIdentifier.plot_d1p(step, data, save_dir)

    filename = joinpath(save_dir, "output_$(datestr)_frame_$(lpad(step, 3, '0'))")

    savefig(final_plot_layout, "$(filename).png")
    if html
        savefig(final_plot_layout, "$(filename)_zoomable.html")
    end

    @info "Saved frame $step as $filename"
end
