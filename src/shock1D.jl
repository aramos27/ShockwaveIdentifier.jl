
#Extract information from .tape and save as EulerSim
function load_sim_data(filename; T=Float64)
	return Euler2D.load_euler_sim((filename); T)
end

#Returns plot boundaries for 1D case. (Used in plotframe)
function plot_bounds(sim::EulerSim{N,NAXES,T}) where {N,NAXES,T}
	bounds = [(minimum(u), maximum(u)) for u ∈ eachslice(sim.u; dims=1)]
	return map(bounds) do (low, up)
		diffhalf = abs(up - low)/2
		mid = (up + low) / 2
		return (mid-1.1*diffhalf, mid+1.1*diffhalf)
	end
end

# At 300K
const DRY_AIR = CaloricallyPerfectGas(1004.9u"J/kg/K", 717.8u"J/kg/K", 0.0289647u"kg/mol")

#= 
	Computes the average mean difference across a dataset data (1D!).
	Used for determining shockwaves by comparing local gradient against average gradient.
=#
function averageGradient(data)
	
	unit = u"1"
	try
		unit = Unitful.unit(data[1])
	catch 
		println("Dimensionless data, or corruptes data? ")

	end

	divergence = 0unit


	for i in eachindex(data)[1:end-1]
		divergence += abs(data[i+1] - data[i])
	end
	
	#print("Div:", divergence)

	#ignore points where data value is very small, decreasing chance of false positives
	filtered_data = filter(x -> abs(x) > 10e-3unit, data)
	if isempty(filtered_data)
		return 0unit
	end

	return divergence / length(filtered_data)
end

#Returns the maximum value of gradient evalueated at all points (1d). 
function maxGradient(data)
	unit = u"1"
	try
		unit = Unitful.unit(data[1])
	catch 
		println("Dimensionless data, or corruptes data? ")

	end
	maximum_gradient = 0unit
	for i in eachindex(data)[1:end-1]
		if abs(data[i+1] - data[i]) > maximum_gradient
			maximum_gradient = abs(data[i+1] - data[i])
			#cprint(" Shockwave detected at ", i)
		end
	end
	return maximum_gradient
end

#=
	Find all points in data where the gradient exceeds the threshold.
=#
function discontinuities(data, threshold)
	indices = []
	gradient = diff(data)
    # Iterate over each gradient with its index
    for (i, difference) in enumerate(gradient)
        if abs(difference) >= threshold
            push!(indices, i)
            # println("Shockwave detected at index ", i)
        end
    end

    return indices
end

#= IS THIS FUNCTION NEEDED???? IMPORTANT
function find_shockwaves(indices::Vector{Int})
    shockwaves = Vector{Shockwave}()
    n = length(indices)

    if n == 0
        return shockwaves
    end

    xBegin = indices[1]

    for i in 1:(n-1)
        if indices[i+1] - indices[i] != 1
            # End of a contiguous sequence
            push!(shockwaves, Shockwave(xBegin, indices[i]))
            xBegin = indices[i+1]
        end
    end

    # Add the last shockwave if it hasn't been added
    push!(shockwaves, Shockwave(xBegin, indices[end]))

    return shockwaves
end
=#


function findShock(data)
    
    unit = u"1"
	try
		unit = Unitful.unit(data[1])
	catch 
		println("Dimensionless data, or corruptes data? ")

	end

	threshold = 0.5 * (averageGradient(data) + maxGradient(data))
	return discontinuities(data, threshold)
	#IS THE REST OF THE FUNCTION NEEDED????? IMPORTANT
	#processing of candidates: filter out the ones

	#probable due to numerical smoothing, the shock wave stretches over multiple cells -> comparison stretched over multiple cells
	CORRECT_SMOOTHING = 1
	SAFETY_FACTOR = 0.69

	max_velocity = maximum(broadcast(abs, data))
	THRESHOLD = max_velocity * SAFETY_FACTOR

	indices = []
	for i in eachindex(data)[1:end-1-CORRECT_SMOOTHING]
		if abs(data[i] - data[i+1+CORRECT_SMOOTHING]) >= THRESHOLD
			push!(indices, i)
			#push!(indices, i+1)
			#cprint(" Shockwave detected at ", i)
		end
	end
	#print("\n")
	
	for i in eachindex(indices)[1:end-1]

		if indices[i+1] - indices[i] == 1
			#remove duplicates
			deleteat!(indices, i)
		end
	end
	
	return indices 
end

# Plots data of 1d case without shockwave
function plotframe(frame, data::EulerSim{1, 3, T}, bounds) where {T}
	(t, u_data) = nth_step(data, frame)
	xs = cell_centers(data, 1)
	ylabels=[L"ρ", L"ρv", L"ρE"]
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
	pressure_plot=plot(xs, p_data, ylabel=L"P", legend=false)
	velocity_plot=plot(xs, v_data, ylabel=L"v", legend=false)
	titlestr = @sprintf "n=%d t=%.4e" frame t
	plot!(ps[1], ps[2], velocity_plot, pressure_plot, suptitle=titlestr, titlefontface="Computer Modern")
	savefig("plot1d.png")
    gui()
end

#=
	Plot the frame with shockwave detection
	Using only the velocity data yields good results.
=#
function plotframe(frame, data::EulerSim{1, 3, T}, bounds, shockwave_algorithm) where {T}
	
	(t, u_data) = nth_step(data, frame)
	xs = cell_centers(data, 1)
	ylabels=[L"ρ", L"ρv", L"ρE"]
    ps = []

    # Get Velocity out of ConservedProps
    v_data = map(eachcol(u_data)) do u
        c = ConservedProps(u)
        v = velocity(c)[1]
    end

    # Detect the shockwave position using the provided algorithm
    x_shock = shockwave_algorithm(v_data)

    # density, momentum, and energy
    for i = 1:3
        p = plot(xs, u_data[i, :], legend=(i==1), label=false, ylabel=ylabels[i],
                 xticks=(i==3), xgrid=true, ylims=bounds[i], dpi=600)
        scatter!(p, [xs[x_shock]], [u_data[i, x_shock]], label="Shockwave", color="orange")
        push!(ps, p)
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
    plot(ps[1], density_gradient_plot, ps[2], pressure_plot, pressure_gradient_plot, velocity_plot, 
         suptitle=titlestr, titlefontface="Computer Modern")
end

function generate_shock_plots(filename::String; save_dir::String = "frames", shockwave_algorithm = findShock)
    # Load simulation data
    DATA = load_sim_data(filename)
    boundary = plot_bounds(DATA)

    # Generate the current date and time in the desired format
    datestr = Dates.format(now(), "mm-dd-HH-MM-SS")

    # Create directory if it doesn't exist
    if !isdir(save_dir)
        mkdir(save_dir)
    end

    # Generate PNG files sequentially
    for i = 1:DATA.nsteps
        p = plotframe(i, DATA, boundary, shockwave_algorithm)
        filename = joinpath(save_dir, "output_$(datestr)_frame_$(lpad(i, 3, '0')).png")
        savefig(p, filename)
        println("Saved frame $i as $filename")
    end
end