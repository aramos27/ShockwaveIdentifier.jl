#Extract information from .tape and save as EulerSim. For .celltape files, use load_cell_data directly.
function load_sim_data(filename; T=Float64)
	return Euler2D.load_euler_sim((filename); T)
end

function load_data(filename; T=Float64)
    if endswith(filename, ".tape")
        return Euler2D.load_euler_sim(filename; T)
    elseif endswith(filename, ".celltape")
        return Euler2D.load_cell_sim(filename)
    else
        error("Unsupported file extension. Only '.tape' and '.celltape' files are supported.")
    end
end


#=
Type support for EulerSim (2D <=> EulerSim{2, 4, T}) and CellBasedEulerSim.
=#

#Returns matrix with pressure data
function compute_pressure_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    pressure_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return uconvert(u"Pa", pressure(c, DRY_AIR))
        
    end
    return pressure_data
end


function compute_pressure_data(frame, data::CellBasedEulerSim)
    p = pressure_field(data, frame, DRY_AIR)
    f = map(p) do val
		isnothing(val) ? 0. : ustrip(val)
    end
    return f
end

#Returns matrix with velocity data
function compute_velocity_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    velocity_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return velocity(c, DRY_AIR)
    end
    return velocity_data
end


function compute_velocity_data(frame, data::CellBasedEulerSim{T}) where {T}
    v = velocity_field(data, frame)

    v_filt = map(v) do val
		isnothing(val) ? 0. : ustrip.(val)
    end

    #@show typeof(v_filt)
    
    # A very complicated line of code over the matrix to convert v, which seems to be a 2 * x * y matrix, into a x * y matrix with Static Vectors of size 2 ( SVector{2, Float64})
    f = [SVector{2, T}(v_filt[1, i, j], v_filt[2, i, j]) for i in 1:size(v_filt, 2), j in 1:size(v_filt, 3)]

    #@show typeof(f)
    return f
end

#Returns matrix with density data
function compute_density_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    # Compute density data from the conserved properties
    density_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return c.ρ
    end

    return density_data
end

function compute_density_data(frame, data::CellBasedEulerSim)
    rho = density_field(data,frame)
    f = map(rho) do val
		isnothing(val) ? 0. : ustrip(val)
    end
    return f
end

#Return matrix of normalized velocity vectors
function normalized_velocity(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}
    velocity_xy = compute_velocity_data(frame, data)
    velocity_xy = ustrip.(velocity_xy)
    for i in 1:size(velocity_xy, 1)  # Iterate over rows
        for j in 1:size(velocity_xy, 2)  # Iterate over columns
            element = velocity_xy[i, j]
            magnitude = sqrt(element[1]^2 + element[2]^2)
            if magnitude != 0  # Compare magnitude to zero with units
                velocity_xy[i, j] = (element / (magnitude ))  # Normalize with units
            end
        end
    end

    return velocity_xy
end

function compute_velocity_magnitude_data(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}
    v = compute_velocity_data(frame, data)
    v_n = broadcast(norm, v)
    return v_n
end


#Given a matrix A with elements of type [x,y] and a matrix B of type float, it returns A/B
function divide_matrices_1(matrix1, matrix2)
 
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
            result[i, j] = SVector{x2, y2}()
        end
    end

    return result
end

function divide_matrices(matrix1, matrix2) 
    if size(matrix1) != size(matrix2)
        throw(ArgumentError("Matrices must have the same dimensions"))
    end

    # Create a new matrix with the same dimensions and type
    result = similar(matrix1, eltype(matrix1))

    # Iterate through the matrices and perform the division
    for i in 1:size(matrix1, 1)
        for j in 1:size(matrix1, 2)
            # Extract the SVector and the corresponding element from the second matrix
            (x1, y1) = matrix1[i, j]
            q2 = matrix2[i, j]

            # Check for division by zero if necessary (depending on your application)
            if q2 == 0
                #@info "Division by zero at position ($i, $j)"
                result[i, j] = SVector(x1, y1) # try to catch this error when dividing through zero, hoping that the matrix1 value is also zero.
            else
                # Normalize the SVector by dividing its components by the quantity
                x2 = x1 / Float64(q2)  # Convert Unitful quantity to Float64
                y2 = y1 / Float64(q2)

                # Store the result as an SVector in the new matrix
                result[i, j] = SVector(x2, y2)
            end
        end
    end

    return result
end
