#Returns plot boundaries for 1D case. (Used in plotframe)
function plot_bounds(sim::EulerSim{N,NAXES,T}) where {N,NAXES,T}
	bounds = [(minimum(u), maximum(u)) for u ∈ eachslice(sim.u; dims=1)]
	return map(bounds) do (low, up)
		diffhalf = abs(up - low)/2
		mid = (up + low) / 2
		return (mid-1.1*diffhalf, mid+1.1*diffhalf)
	end
end


# Plots data of 1d case without shockwave detection.
function plotframe1D(frame, data::EulerSim{1, 3, T}) where {T}
	(t, u_data) = nth_step(data, frame)
	xs = cell_centers(data, 1)
	ylabels=[L"ρ", L"ρv", L"ρE"]
    bounds = plot_bounds(data)
	ps = [
		plot(xs, u_data[i, :], legend=(i==1), label=false, ylabel=ylabels[i], xticks=(i==3), xgrid=true, ylims=bounds[i], dpi=600) 
		for i=1:3]
	v_data = map(eachcol(u_data)) do u
		c = ConservedProps(u)
		v = velocity(c)[1]
	end
	p_data = map(eachcol(u_data)) do u
		c = ConservedProps(u)
		return uconvert(u"Pa", pressure(c, DRY_AIR))
	end
	pressure_plot = plot(xs, p_data, ylabel=L"P", legend=false)
	velocity_plot = plot(xs, v_data, ylabel=L"v", legend=false)
	titlestr = @sprintf "n=%d t=%.4e" frame t
	plot!(ps[1], ps[2], velocity_plot, pressure_plot, suptitle=titlestr, titlefontface="Computer Modern")
	savefig("plot1d.png")
end

#=
	Plot the frame with shockwave detection
	Using only the velocity data yields good results.
=#
function plotframe1D(frame, data::EulerSim{1, 3, T}, shockwave_algorithm, save = false) where {T}
	(t, u_data) = nth_step(data, frame)
	xs = cell_centers(data, 1)
	ylabels=[L"ρ", L"ρv", L"ρE"]
    ps = []
    bounds = plot_bounds(data)
    # Detect the shockwave position using the provided algorithm
    x_shock = shockwave_algorithm(frame, data)
    #x_shock = shockwave_algorithm(v_data)

    # density, momentum, and energy
    for i = 1:3
        p = plot(xs, u_data[i, :], legend=(i==1), label=false, ylabel=ylabels[i],
                 xticks=(i==3), xgrid=true, ylims=bounds[i], dpi=600)
        scatter!(p, [xs[x_shock]], [u_data[i, x_shock]], label="Shockwave", color="orange")
        push!(ps, p)
    end

    # Get Velocity out of ConservedProps
    v_data = map(eachcol(u_data)) do u
        c = ConservedProps(u)
        v = velocity(c)[1]
    end

    # Get Pressure out of ConservedProps
    p_data = map(eachcol(u_data)) do u
        c = ConservedProps(u)
        return uconvert(u"Pa", pressure(c, DRY_AIR))
    end

    # Pressure
    pressure_plot = plot(xs, p_data, ylabel=L"P", legend=false)
    scatter!(pressure_plot, [xs[x_shock]], [p_data[x_shock]], label="Shockwave", color="orange")

    # Velocity
    velocity_plot = plot(xs, v_data, ylabel=L"v", legend=false)
    scatter!(velocity_plot, [xs[x_shock]], [v_data[x_shock]], label="Shockwave", color="orange")

    # Gradient Pressure
    pressure_gradient = diff(p_data)
    gradient_xs = xs[1:end-1] + diff(xs)/2 # Adjust xs for gradient plot
    pressure_gradient_plot = plot(gradient_xs, pressure_gradient, ylabel=L"\nabla P", legend=false)

    # Gradient Density
    density_gradient = diff(u_data[1, :])
    density_gradient_plot = plot(gradient_xs, density_gradient, ylabel=L"\nabla ρ", legend=false)

    # Plotting
    scatter!(pressure_gradient_plot, [xs[x_shock]], [pressure_gradient[x_shock]], label="Shockwave", color="orange")
    scatter!(density_gradient_plot, [xs[x_shock]], [density_gradient[x_shock]], label="Shockwave", color="orange")

   
    titlestr = @sprintf "n=%d t=%.4e" frame t

    # Plot of a plot
    fig =  plot(ps[1], density_gradient_plot, ps[2], pressure_plot, pressure_gradient_plot, velocity_plot, 
         suptitle=titlestr, titlefontface="Computer Modern")
    if save == true
        savefig(fig, "plot1d_shock")
    end
    return fig
end

function generate_shock_plots1D(filename::String; save_dir::String = "frames", shockwave_algorithm = findShock1D)
    # Load simulation data
    DATA = load_sim_data(filename)

    # Generate the current date and time in the desired format
    datestr = Dates.format(now(), "mm-dd-HH-MM-SS")

    # Create directory if it doesn't exist
    if !isdir(save_dir)
        mkdir(save_dir)
    end

    # Generate PNG files sequentially
    for i = 1:DATA.nsteps
        p = plotframe1D(i, DATA, shockwave_algorithm)
        filename = joinpath(save_dir, "output_$(datestr)_frame_$(lpad(i, 3, '0')).png")
        savefig(p, filename)
        println("Saved frame $i as $filename")
    end
end

"""for 1D/scalar heatmaps (e.g. δ_1ρ  and δ_2ρ )"""	
function plot_1d_heatmap(magnitude, filename::String)
 
    heatmap_plot = heatmap(
    magnitude, 
    title="Heatmap", 
    xlabel="X-axis", 
    ylabel="Y-axis", 
    color=:viridis,
    aspect_ratio=1  # square plot
)
    if filename == ""
        filename = "heatmap.png"
    end
    
    savefig(heatmap_plot, filename)
end

#Plots for 2d grid with compute_data_function at data[frame] for a quantity, e.g. pressure.
function plotframe2D(frame, data::EulerSim{2, 4, T}, compute_data_function) where {T}
    (t, u_data) = nth_step(data, frame)
    xs, ys = cell_centers(data)
    plot_data = compute_data_function(frame, data)

    # Determine the header based on the data's units
    header = ""
    # Use eltype to check if the elements are Unitful.Quantity
    if eltype(plot_data) <: Unitful.Quantity
        unit_type = unit(plot_data[1,1])

        # Match against known units for pressure, velocity, or density
        if unit_type == u"Pa"  # Pressure (Pascals)
            header = "Pressure (Pa)"
        elseif unit_type == u"m/s"  # Velocity (meters per second)
            header = "Velocity (m/s)"
        elseif unit_type == u"kg/m^3"  # Density (kilograms per cubic meter)
            header = "Density (kg/m³)"
        else
            header = "Unknown Data"
        end
    else
        header = "Unknown Data"
    end

    #Plotting
    heatmap_plot = heatmap(xs, ys, plot_data, aspect_ratio=:1, size= (1000,1000), title=header, color=:viridis, xlabel="X", ylabel="Y")
    final_plot_layout = plot(heatmap_plot)

    # Display and save the plot
    savefig(final_plot_layout, "plot_frame2d_$(frame)_$(header).png")
end

#Plots heatmap of d1p. Mainly for debug purposes.
function plot_d1p(frame, data::EulerSim{2,4,T}, save_dir::AbstractString) where {T}
    datestr = Dates.format(now(), "mm-dd-HH-MM-SS")
    d1p = delta_1p(frame, data)
    #Plotting
    delta_1rho_plot = heatmap(
        d1p, 
        title="δ_1ρ step $frame", 
        xlabel="X-axis", 
        ylabel="Y-axis", 
        color=:viridis,
        aspect_ratio=1,  # Square heatmap
        #size= (5000,5000) #5k resolution is too much for the disk.
        )
    plot(delta_1rho_plot)
    filename = joinpath(save_dir, "delta_1p_$(datestr)_frame_$(lpad(frame, 3, '0')).png")
    savefig(delta_1rho_plot, filename)


end

#Plots heatmap of d2p. Mainly for debug purposes.
function plot_d2p(frame, data::EulerSim{2,4,T}, save_dir::AbstractString) where {T}
    d2p = delta_2p(frame, data)
    datestr = Dates.format(now(), "mm-dd-HH-MM-SS")
    #Plotting
    delta_2rho_plot = heatmap(
        d2p, 
        title="δ_2ρ step $frame", 
        xlabel="X-axis", 
        ylabel="Y-axis", 
        color=:viridis,
        aspect_ratio=1,  # Ensures the heatmap is square
        #size= (5000,5000)
        )
        
    plot(delta_2rho_plot)
    filename = joinpath(save_dir, "delta_2p_$(datestr)_frame_$(lpad(frame, 3, '0')).png")
    savefig(delta_2rho_plot, filename)

end

function plotframe2D(frame, data::EulerSim{2, 4, T}, compute_data_function, shockwave_algorithm , vectors = false) where {T}
    (t, u_data) = nth_step(data, frame)
    xs, ys = cell_centers(data)
    shock_points = shockwave_algorithm(frame, data)
    plot_data = compute_data_function(frame, data)

    # Determine the header based on the data's units
    header = ""
    # Use eltype to check if the elements are Unitful.Quantity
    if eltype(plot_data) <: Unitful.Quantity
        unit_type = unit(plot_data[1,1])

        # Match against known units for pressure, velocity, or density
        if unit_type == u"Pa"  # Pressure (Pascals)
            header = "Pressure (Pa)"
        elseif unit_type == u"m/s"  # Velocity (meters per second)
            header = "Velocity (m/s)"
        elseif unit_type == u"kg/m^3"  # Density (kilograms per cubic meter)
            header = "Density (kg/m³)"
        else
            header = "Unknown Data"
        end
    else
        header = "Unknown Data"
    end

    # Plotting heatmaps
    #Plotting
    heatmap_plot = heatmap(xs, ys, plot_data, aspect_ratio=:1, size= (1000,1000), title=header, color=:viridis, xlabel="X", ylabel="Y")
    

    # Extract shock point coordinates
    shock_xs = [xs[i] for (i, j) in shock_points]
    shock_ys = [ys[j] for (i, j) in shock_points]

    # Overlay shock points on both plots
    scatter!(heatmap_plot, shock_xs, shock_ys, color=:red, label="Shock Points", markersize=2, marker=:cross)

    if vectors
        print("Vectors")
    end
    final_plot_layout = plot(heatmap_plot)
    savefig(final_plot_layout, "2d_shock_frame_$(lpad(frame, 3, '0')).png")
    savefig(final_plot_layout, "2d_shock_zoomable_frame_$(lpad(frame, 3, '0')).html")
end