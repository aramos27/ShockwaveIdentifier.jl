""" 
	Computes the average mean difference across a dataset data (1D!).
	Used for determining shockwaves by comparing local gradient against average gradient.
	Ignores small gradients (<ϵ).
"""
function averageGradient(data)
	
	unit = u"1"
	try
		unit = Unitful.unit(data[1])
	catch 
		@warn "Dimensionless data, or corruptes data? Unitful.unit could not be applied."
	end

	divergence = 0unit


	for i in eachindex(data)[1:end-1]
		divergence += abs(data[i+1] - data[i])
	end
	
	ϵ = 10e-3unit
	filtered_data = filter(x -> abs(x) > ϵ, data)
	if isempty(filtered_data)
		return 0unit
	end

	return divergence / length(filtered_data)
end

"""Returns the maximum value of gradient of the vector/array data evalueated at all points (1d) """
function maxGradient(data)
	unit = u"1"
	try
		unit = Unitful.unit(data[1])
	catch 
		@warn "Dimensionless data, or corruptes data? Unitful.unit could not be applied."
	end

	maximum_gradient = 0unit
	for i in eachindex(data)[1:end-1]
		if abs(data[i+1] - data[i]) > maximum_gradient
			maximum_gradient = abs(data[i+1] - data[i])
		end
	end
	return maximum_gradient
end

"""
	Find all points in the vector/array data where the gradient exceeds the scalar threshold, treating it as a discontinuity at that point.
"""
function discontinuities(data, threshold)
	indices = []
	gradient = diff(data)
    # Iterate over each gradient with its index
    for (i, difference) in enumerate(gradient)
        if abs(difference) >= threshold
            push!(indices, i)
        end
    end


	#=
	If too many points above threshold present in the current frame, we suspect a malfunction. This potentially prohibits the detection of complicated shocks. For 1D, it should be fine.
	=#
	n_shocks = size(indices)[1]
	n_points = size(data)[1]
	ϵ_no_shocks = 0.2 # when more then 20% of all points are shocks, something is wrong.
	if n_shocks/n_points > ϵ_no_shocks
		@warn "Too many shock points, not physically feasible! Treated as malfunctioning frame."
		indices = []
	end

	#If maximum gradient is not deviating too much from the average gradient, we will also suspect something is wrong.
	#Not implemented yet - necessary?

    return indices
end

"""
Our developed approach to detect shock wave points in 1D, based on a simple approach with a gradient threshold.
The gradient threshold is the maximum gradient value multiplied by a constant threshold (default 0.5), which manages to detect all shocks in the test cases that we have received and to ignore high gradients caused by expansion waves, which can be visualized through the debug flag of generate_shock_plots1D.
We compare the weighted density gradient (density gradient multiplied by velocity) and velocity gradient. Both need to be above the threshold to suffice our shock condition. 

Input arguments:
	- frame: the frame-th step that of the simulation object that shall be processed.
    - data: EulerSim{1, 3, T} object generated by Euler2D.
	- threshold: (optional, default 0.5) factor of the maximum gradient
    Shall return a list of indices where shockpoints are assumed.

"""
function findShock1D(frame, data::EulerSim{1, 3, T}; threshold=eps_1d) where{T}
    (t, u_data) = nth_step(data, frame)
	
	#Density data is u_data[]
	grad_max = maxGradient(u_data[1, :])
	grad_avg = averageGradient(u_data[1, :])

	unit = u"1"
	try
		unit = Unitful.unit(grad_avg)
	catch 
		@warn "Dimensionless data, or corruptes data? Unitful.unit could not be applied."
	end

	# Get Velocity out of ConservedProps
	v_data = map(eachcol(u_data)) do u
		c = ConservedProps(u)
		v = velocity(c)[1]
	end
	v_data = ustrip.(v_data)
	v_norm = normalize(v_data)

	if grad_max != 0unit 
		#check velocity data
		grad_max_v = maxGradient(v_data)		
		threshold_v = threshold * (grad_max_v)
		shock_points_v = findall(x->abs(x) > threshold_v, v_data)


		#check density data according to 2D approach.
		density_data = u_data[1, :]
		d1p = diff(density_data) .* normalize(ustrip.(v_data)[1:(end-1)])
		push!(d1p,0) #compensate for diff losing one element of the array
		
		grad_max_dp = maximum(d1p)
		threshold = threshold * (grad_max_dp)
		shock_points_d1p = findall(x->abs(x) > threshold, d1p)
		shock_points = []
		for sp_v in shock_points_v
			if sp_v in shock_points_d1p
				push!(shock_points, sp_v)
			end
		end

		return shock_points #Shockpoint candidates
	else
		@info "Gradient of density is zero. Switching to approach based on 2D."
		density_data = u_data[1, :]

		#analogue aproach to 2D: We compare the gradient of density multiplied by normalized velocity
		d1p = diff(density_data) .* normalize(ustrip.(v_data)[1:(end-1)])
		push!(d1p,0)

		grad_max = maximum(d1p)
		@info "Max d1p: " maximum(d1p)

		threshold = 0.5 * (grad_max) #find some formula for the threshold. like this, it seems to work.

		@info "Threshold: " threshold

		shock_points = findall(x->abs(x) > threshold, d1p)
		return shock_points #Shockpoint candidates
	end
end

"""
    This function iterates over all frames in the given data and finds shock points
    for each frame of the simulation object data::EulerSim{1, 3, T} using the findShock1D function.
"""
function findAllShocks1D(data::EulerSim{1, 3, T}, threshold = eps_1d) where{T}
    shock_points = []

    num_frames = Euler2D.n_tsteps(data)  
    # Loop over each frame
    for frame in 1:num_frames
        # Find shocks for the current frame using the previously defined function
        shock = findShock1D(frame, data, threshold=threshold)

        # Append the list of shock points for the current frame to the shock_points list
        push!(shock_points, shock)
    end

    return shock_points
end

