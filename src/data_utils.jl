#Extract information from .tape and save as EulerSim
function load_sim_data(filename; T=Float64)
	return Euler2D.load_euler_sim((filename); T)
end

#Returns matrix with pressure data
function compute_pressure_data(frame, data::EulerSim{2, 4, T}) where {T}
    (t, u_data) = nth_step(data, frame)
    pressure_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return uconvert(u"Pa", pressure(c, DRY_AIR))
        
    end

    return pressure_data
end


#Returns matrix with velocity data
function compute_velocity_data(frame, data::EulerSim{2, 4, T}) where {T}
    (t, u_data) = nth_step(data, frame)
    velocity_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        #print(velocity(c, DRY_AIR))
        return velocity(c, DRY_AIR)
    end

    return velocity_data
end

#Returns matrix with density data
function compute_density_data(frame, data::EulerSim{2,4, T}) where {T}
    (t, u_data) = nth_step(data, frame)
    # Compute density data from the conserved properties
    density_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return c.ρ
    end

    return density_data
end


#Return matrix of normalized velocity vectors
function normalized_velocity(frame, data::EulerSim{2, 4, T}) where {T}
    velocity_xy = compute_velocity_data(frame, data)
    for i in 1:size(velocity_xy, 1)  # Iterate over rows
        for j in 1:size(velocity_xy, 2)  # Iterate over columns
            element = velocity_xy[i, j]
            #print(element)
            magnitude = sqrt(element[1]^2 + element[2]^2)
            if magnitude != 0u"m/s"  # Compare magnitude to zero with units
                velocity_xy[i, j] = (element / (magnitude * u"1"))u"m/s"  # Normalize with units
            end
        end
    end
    return velocity_xy
end

#Given a matrix A with elements of type [x,y] and a matrix B of type float, it returns A/B
function divide_matrices(matrix1, matrix2)
 
    if size(matrix1) != size(matrix2)
        throw(ArgumentError("Matrices must have the same dimensions"))
    end

    # Create a new matrix with the same dimensions
    result = similar(matrix1, eltype(matrix1))

    # Iterate through the matrices and perform the division
    for i in eachindex(matrix1)
        for j in eachindex(matrix1, 2)
            # Extract the values from matrix2 (divisor) and matrix1 (dividend)
            (x1, y1) = matrix1[i, j]
            q2 = matrix2[i, j]

            # Divide the elements by the value of the quantity (convert to Float64)
            x2 = x1 / Float64(q2)
            y2 = y1 / Float64(q2)

            # Store the result as a tuple in the new matrix
            result[i, j] = (x2, y2)
        end
    end

    return result
end