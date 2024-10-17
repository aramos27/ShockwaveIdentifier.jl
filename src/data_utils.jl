#Extract information from .tape and save as EulerSim. For .celltape files, use load_cell_data directly.
function load_sim_data(filename; T=Float64)
	return Euler2D.load_euler_sim((filename); T)
end

"""
    load_data(filename; T=Float64)

Load an array-based or cell-based simulation from `filename`. Supports `.tape` and `.celltape` files.

# Arguments
- `filename`: The path to the file to load (`.tape` or `.celltape`).
- `T`: (Optional) The data type to use for the simulation, default is `Float64`.

# Returns
An `EulerSim` or `CellBasedEulerSim` object based on the file type.
"""
function load_data(filename; T=Float64)
    if endswith(filename, ".tape")
        return Euler2D.load_euler_sim(filename; T)
    elseif endswith(filename, ".celltape")
        return Euler2D.load_cell_sim(filename)
    else
        error("Unsupported file extension. Only '.tape' and '.celltape' files are supported.")
    end
end



"""
    compute_pressure_data(frame, data::EulerSim{2,4,T}) where {T}

Returns a matrix of pressure data with units for a given array-based simulation.

# Arguments
- `frame`: The frame number to extract the pressure data from.
- `data`: An array-based simulation (`EulerSim{2,4,T}`).

# Returns
A matrix containing the pressure values with appropriate units.
"""
function compute_pressure_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    pressure_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return uconvert(u"Pa", pressure(c, DRY_AIR))
        
    end
    return pressure_data
end

"""
    compute_pressure_data(frame, data::CellBasedEulerSim)

Returns a matrix of pressure data with units for a given cell-based simulation.

# Arguments
- `frame`: The frame number to extract the pressure data from.
- `data`: A cell-based simulation (`CellBasedEulerSim`).

# Returns
A matrix containing the pressure values with units stripped.
"""
function compute_pressure_data(frame, data::CellBasedEulerSim)
    p = pressure_field(data, frame, DRY_AIR)
    f = map(p) do val
		isnothing(val) ? 0. : ustrip(val)
    end
    return f
end

"""
    compute_velocity_data(frame, data::EulerSim{2,4,T}) where {T}

Returns a matrix of velocity data with units for a given array-based simulation.

# Arguments
- `frame`: The frame number to extract the velocity data from.
- `data`: An array-based simulation (`EulerSim{2,4,T}`).

# Returns
A matrix containing the velocity values.
"""
function compute_velocity_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    velocity_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return velocity(c, DRY_AIR)
    end
    return velocity_data
end

"""
    compute_velocity_data(frame, data::CellBasedEulerSim{T}) where {T}

Returns a matrix of velocity data with units for a given cell-based simulation.

# Arguments
- `frame`: The frame number to extract the velocity data from.
- `data`: A cell-based simulation (`CellBasedEulerSim{T}`).

# Returns
A matrix containing velocity vectors (as static vectors).
"""
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

"""
    compute_density_data(frame, data::EulerSim{2,4,T}) where {T}

Returns a matrix of density data with units for a given array-based simulation.

# Arguments
- `frame`: The frame number to extract the density data from.
- `data`: An array-based simulation (`EulerSim{2,4,T}`).

# Returns
A matrix containing the density values.
"""
function compute_density_data(frame, data::EulerSim{2,4,T}) where {T}
    (t, u_data) = nth_step(data, frame)
    # Compute density data from the conserved properties
    density_data = map(eachslice(u_data; dims=(2,3))) do u
        c = ConservedProps(u[1:end])
        return c.ρ
    end

    return density_data
end


"""
    compute_density_data(frame, data::CellBasedEulerSim)

Returns a matrix of density data with units for a given cell-based simulation.

# Arguments
- `frame`: The frame number to extract the density data from.
- `data`: A cell-based simulation (`CellBasedEulerSim`).

# Returns
A matrix containing the density values with units stripped.
"""
function compute_density_data(frame, data::CellBasedEulerSim)
    rho = density_field(data,frame)
    f = map(rho) do val
		isnothing(val) ? 0. : ustrip(val)
    end
    return f
end

"""
    normalized_velocity(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}

Returns a matrix of normalized velocity vectors for both array-based and cell-based simulations.

# Arguments
- `frame`: The frame number to extract the velocity data from.
- `data`: A simulation (`EulerSim{2,4,T}` or `CellBasedEulerSim{T}`).

# Returns
A matrix of normalized velocity vectors.
"""
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

"""
    compute_velocity_magnitude_data(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}

Returns a matrix of velocity magnitudes for both array-based and cell-based simulations.

# Arguments
- `frame`: The frame number to extract the velocity data from.
- `data`: A simulation (`EulerSim{2,4,T}` or `CellBasedEulerSim{T}`).

# Returns
A matrix of velocity magnitudes.
"""
function compute_velocity_magnitude_data(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}
    v = compute_velocity_data(frame, data)
    v_n = broadcast(norm, v)
    return v_n
end

"""
    divide_matrices(matrix1, matrix2)

Given a matrix `matrix1` of vectors [x, y] and a matrix `matrix2` of scalar values, return the result of `matrix1 / matrix2` element-wise.

# Arguments
- `matrix1`: A matrix with vector elements (e.g., `SVector`).
- `matrix2`: A matrix with scalar elements.

# Returns
A new matrix where each vector in `matrix1` is divided by the corresponding scalar in `matrix2`.
"""
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
