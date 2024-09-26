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

#=
	Find all candidates for shockwaves within a 1d Data set.

function findShock1D(data)
    
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
=#

function findShock1D(frame, data::EulerSim{1, 3, T}) where{T}
    (t, u_data) = nth_step(data, frame)

    # Get Velocity out of ConservedProps
    v_data = map(eachcol(u_data)) do u
        c = ConservedProps(u)
        v = velocity(c)[1]
    end

    threshold = 0.5 * (averageGradient(v_data) + maxGradient(v_data))
	
	return discontinuities(v_data, threshold)
end