
"""
Returns matrix containing a vector (∂ρ/∂x, ∂ρ/∂y) at each point, with grid sizes hx and hy of data_no_units.
imgradients from Images library. Uses convolution methods and seems to be faster.
Takes as input:
- data_no_units: Matrix of values.
- hx: grid size x.
- hy: grid size y.
"""
function gradient_2d(data_no_units, hx, hy)
    rows, cols = size(data_no_units)

    # Compute the gradients in both x and y directions
    gradients = imgradients(data_no_units, KernelFactors.ando3)

    # Allocate result array of SVectors (2-element statically sized vectors)
    gradient_2d_result = Array{SVector{2, Float64}, 2}(undef, rows, cols)

    # Fill the result array with scaled gradients
    for i in 1:rows
        for j in 1:cols
            gradient_2d_result[i, j] = @SVector [gradients[1][i, j] / hx, gradients[2][i, j] / hy]
        end
    end

    return gradient_2d_result
end

"""
takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
- compute_data_function: function that computes some value such as pressure and returns a matrix of physical properties over a discretized field, optimally. E.g. compute_pressure_data

Calls gradient_2d(data_no_units, hx, hy) after formatting data accordingly.
"""
function gradient_2d(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}, compute_data_function) where {T}

    # Check if the data is an EulerSim or a regular Float64 array
    if typeof(data) <: Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}
        # If it's an EulerSim, extract the density data at the specified frame
        if frame === nothing
            error("Frame number must be provided when using EulerSim data")
        end
        data_units = compute_data_function(frame, data)
        data_no_units = ustrip.(data_units)  # Strip units for computation
    elseif typeof(data) <: AbstractArray{<:Real, 2}
        # If it's a Float64 array, use it directly
        data_no_units = data
    else
        error("Unsupported data type. Input must be an EulerSim or a 2D Float64 array.")
    end

    #h := next cell.
    #assuming equidistant grid
    h_x = 1
    h_y = 1
    try
        h_x = cell_centers(data)[1][2] - cell_centers(data)[1][1]
        h_y =  cell_centers(data)[2][2] - cell_centers(data)[2][1]
    catch y
        warn("h was not computed correctly. assuming h=1: ", y)

    end
    return gradient_2d(data_no_units, h_x, h_y)

end


"""
takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
"""
function delta_1p(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}
    #IMPORTANT, ARE THESE VARIABLES NEEDED??
    x_width = last(cell_centers(data)[1]) - cell_centers(data)[1][1]
    y_width = last(cell_centers(data)[2]) - cell_centers(data)[2][1]

    #factor l as the area of computation / computational domain in 2D

    #because the other option (x*y) turns out to be quite large, we will try the grid size instead.
    #state of 10.09.2024: It seems to work.
    
    l = 0.5 * (cell_centers(data)[1][2] - cell_centers(data)[1][1] + cell_centers(data)[2][2] - cell_centers(data)[2][1]) / 2

    ρ = compute_density_data(frame, data)
    ρ = ustrip.(ρ)

    dRho = gradient_2d(frame, data, compute_density_data)
    
    dRho_normalized = divide_matrices(dRho, ρ)

    v = ustrip.(normalized_velocity(frame, data))

    # Convert each Tuple to an SVector
    sdRho = map(x -> SVector{2}(x...), dRho_normalized)
    #sdRho = dRho_normalized
    sdRho = ustrip.(sdRho)
    
    #piecewise dot-product of v and \delta Rho
    d1p = map(dot, v, sdRho)
    #factor l, approx. the computational domain size (linearly)
    d1p *= l

    return d1p
end

"""
Serves the purpose of finding zeros in discretized data discret (Matrix) such as d1p and d2p through sign changes. 
    Wherever a sign change occurs, the values are replaced with 0.

"""
function find_zeros!(discret)
    if ndims(discret) == 1
        
        for i in 2:length(discret)

            #signbit: True if negative. False if positive.
            if signbit(discret[i]) != signbit(discret[i-1])
                if discret[i] != 0 && discret[i-1] != 0
                    discret[i] = 0
                    discret[i-1] = 0
                end
            end
        end
    elseif ndims(discret) == 2
        rows, cols = size(discret)
        
        for i in 1:rows
            for j in 2:cols
                #If sign changes along j axis
                if signbit(discret[i, j]) != signbit(discret[i, j-1])
                    #if values are not zero yet - is this necessary 100%?
                    if discret[i, j] != 0 && discret[i, j-1] != 0
                        #make values zero
                        discret[i, j] = 0
                        discret[i, j-1] = 0
                    end
                end
            end
        end

        for j in 1:cols
            for i in 2:rows
                #if sign changes along y axis
                if signbit(discret[i, j]) != signbit(discret[i-1, j])
                    if discret[i, j] != 0 && discret[i-1, j] != 0
                        discret[i, j] = 0
                        discret[i-1, j] = 0
                    end
                end
            end
        end
    else
        @error "Input must be either a 1D or 2D array."
        #do nothing
        return
    end
    return 
end





"""
takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
Turns 0 for shocks. Presumably, when the density gradient is also not zero.

    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
"""
function delta_2p(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}) where {T}
 

    hx = cell_centers(data)[1][2] - cell_centers(data)[1][1]
    hy = cell_centers(data)[2][2] - cell_centers(data)[2][1]


    d1p = delta_1p(frame, data)


    #formerly problematic. solved by 1. recursion 2. switching to Images for gradient2d
    dd1p = gradient_2d(d1p, hx, hy) 


    # Convert each Tuple to an SVector for compatibility reasons
    dd1p= map(x -> SVector{2}(x...), dd1p)
    #dd1p = dd1p * u"kg/m^3"
    
    d2p = map(dot, normalized_velocity(frame,data), dd1p)
    return ustrip.(d2p)
end

"""
takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
- d1p: Matrix from precomputed d1p value (function delta_1p)
Faster version when d1p is precomputed, taking d1p already into account. 
optional argument d1p shall be a Matrix{T}

Turns 0 for shocks. Presumably, when the density gradient is also not zero.

    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
"""
function delta_2p(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}, d1p::Matrix{T}) where {T}
 

    hx = cell_centers(data)[1][2] - cell_centers(data)[1][1]
    hy = cell_centers(data)[2][2] - cell_centers(data)[2][1]


    #formerly problematic. solved by 1. recursion 2. switching to Images for gradient2d
    dd1p = gradient_2d(d1p, hx, hy) 


    # Convert each Tuple to an SVector for compatibility reasons
    dd1p= map(x -> SVector{2}(x...), dd1p)
    #dd1p = dd1p * u"kg/m^3"
    
    d2p = map(dot, normalized_velocity(frame,data), dd1p)
    return ustrip.(d2p)
end

"""
blank() operates on a frame's precomputed data, taking the input arguments:
d1p: Matrix of 2D-Values of d1p, computed with the equation used for function delta_1p. Basically first gradient of density multiplied by normalized velocity.
d2p: Matrix of 2D-Values of d2p, computed with the equation used for function delta_2p. Basically gradient of d1p wrt. to space  multiplied by normalized velocity.

Blanking part:
Wherever d2p == 0 and d1p != 0, shocks shall be identified.

Needs d1p and d2p as arguments and finds the nul-points of d2p as possible extremals of d1p, and thus shockwaves. To eliminate the rest, only candidates with a d1p value above a certain threshold remain considered.

TODO :
Find eps1, eps2 so that it works. Possible, eps1 will have to depend on the intensity of shockwave. eps2 is set to take into account floating point arithmetic errors.

"""
function blank(d1p::Matrix{T}, d2p::Matrix{T}, eps1::T = eps1_cell, eps2::T = 10e-4) where {T<:Number}
    # Create a blank matrix of the same size as the input matrices
    blanked = zeros(Bool, size(d1p)) 

    #play around with these two parameters. Something is definitely off here.
    #Decreasing eps1 increases the amount of candidates. We set eps1 a bit higher. I am sure there shall be a way to adaptively calculate eps1 to decide what is a significant density gradient.
    #Increasing eps2 increases the amount of candidates, but might lead to the detection of standard propagation waves as shocks.
    find_zeros!(d2p)

    shock_counter = 0

    # Iterate over each element in the input matrices
    for i in 1:size(d1p, 1)
        for j in 1:size(d1p, 2)
            # If both d1p and d2p are zero, set the corresponding element in the blanked matrix to zero
            if abs(d1p[i,j]) > eps1 #d1p != 0
                
                if abs(d2p[i, j]) < eps2 #d2p == 0
                    blanked[i, j] = true
                    
                    shock_counter += 1
                    #println("Shock with d1p $(d1p[i,j]) and d2p $(d2p[i,j]) at $i $j") #debug print
                else
                    #println("Potential Shock with d1p $(d1p[i,j]) and d2p $(d2p[i,j]) at $i $j") #debug print
                end
            else
                blanked[i, j] = false
            end
        end
    end

    return blanked
end

"""
Finds all neighboring points within a given radius from a point `p` on a grid.

# Arguments:
- `p`: A 2D point (centre)
- `r`: The radius within which neighbors should be found.

# Returns:
- A list of all neighbors of point `p` that are within distance `r`.

"""
function find_neighbors(p, r)
    # Return all neighbors within distance 'r' from point 'p' in a grid.
    offsets = collect(product(-r:r, -r:r))
    return [(p[1] + o[1], p[2] + o[2]) for o in offsets if norm(o) <= r]
end


"""
Updates the `shocklist` by adding neighboring points from `shocklist_relaxed` close to points in shocklist.

# Arguments:
- `shocklist`: The current list of shock points.
- `shocklist_relaxed`: Points that meet relaxed criteria for potential shocks.

- `radius`: The radius within which neighbors should be checked. 2 by default.

# Returns:
- Modifies `shocklist` in place, adding neighboring points that satisfy the gradient conditions.

"""
function update_shocklist_refined(shocklist, shocklist_relaxed; radius=2)
    # Use a set to store shocklist for fast lookups and avoid duplicates
    shockset = Set(shocklist)

    # Initialize queue with current shock points
    queue = copy(shocklist)

    # Process points in the queue
    while !isempty(queue)
        # Pop a point from the front of the queue
        point = popfirst!(queue)

        # Find neighbors around the point
        neighbors = find_neighbors(point, radius)

        # Check each neighbor from shocklist_relaxed
        for neighbor in neighbors
            if neighbor in shocklist_relaxed && neighbor ∉ shockset
                # Check if the neighbor has a high gradient
                if true
                    # Add new shock point
                    push!(shocklist, neighbor)
                    push!(shockset, neighbor)
                    push!(queue, neighbor)  # Also add to the queue for further exploration
                end
            end
        end
    end
end

"""
Finds all shockpoints from the dataset data at the frame-th timestep and returns a list of their coordinates. Takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
- threshold: threshold of eps1 variable in blank
- level: 
    - 1 : usual method according to the paper mentioned above (finding extremal points of δ_1_ρ).
    - 2 : applies further nearest-neighbour edge detection with a less harsh condition (blanking threshold lowered), which slows down the function a bit.
    - ⋝ 4 : does NOT add removal  removal of lonely points (presumably noise)
    - ⋝ 5 : does NOT add removal of points near nothing values (obstacles)

"""
function findShock2D(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}; threshold = eps1_euler, level = 2) where {T}
    #Compute δ_1ρ and δ_2ρ at step "frame" and EulerSim "data" (at a timestep of a simulation object).
    d1p = delta_1p(frame, data)
    d2p = delta_2p(frame, data, d1p)

    #=
    "Blank" the matrix. E.q. we look where d1p is bigger than 0.15 (ϵ_1) and where d2p is smaller than 0.00001 (ϵ_2).
    These points are marked with a zero.
    =#
    blanked = blank(d1p, d2p, threshold, 10e-5)

    #The coordinates where we detect a shock condition are put into the array shocklist.
    shocklist = Tuple.(findall(blanked .== true))


    #With help by ChatGPT
    if level == 2
        # Part II: Find neighbors of cells in shocklist with high gradients, but not as high.
        blanked_relaxed = blank(d1p, d2p, 0.2 * threshold, 10e-5) # Relaxed criteria for blanks
        shocklist_relaxed = Tuple.(findall(blanked_relaxed .== true))

        # Find and append neighboring points with less strict gradient conditions
        update_shocklist_refined(shocklist, shocklist_relaxed; radius=2)

        println("Amount of shock points: ", size(shocklist)[1])


    #Watchout! Slow, inefficient, insecure
    elseif level == 6

        # Part II: Find neighbors of cells in shocklist with high gradients, but not as high.
        blanked_relaxed = blank(d1p, d2p, 0.2 * threshold, 10e-5) #blank with lower cutoff threshold.
        shocklist_relaxed = Tuple.(findall(blanked_relaxed .== true))

        #Find points in shocklist_2 (with less strict criteria) who are close to existing shocks, and append them.
        lenList = size(shocklist)[1]
        #@show size(shocklist)[1]
        for points in 1:lenList
            for point1 in shocklist_relaxed
                # Calculate distances between point1 and each point in shocklist
                distances = [norm(point1 .- point2) for point2 in shocklist]
                min_d = minimum(distances)
                
                if min_d < 1.5
                    push!(shocklist, point1)
                    # Construct shockwaves below.
                end
            end
            if points % 5 == 0
                println("Progress (Abs./%): $(points); $(100 * points/(lenList)) %")
            end
        end
    end

    #delete unnecessary shockpoints (false positives)
    #standalone shock points: unlikely to happen
    #=
        In an area around each point of the shocklist, the amount of fellow shock points is evaluated.
        If it is under a certain threshold, we remove the shockpoint from the list as an allegedly lone shock point, which shall not exist. 
        (Or, must be sacrificed, in order to eliminate noise from the solver.)
    =#
    if level < 4
        for point in shocklist
            radiusThreshold = 3
            neighborsOfPoint = find_neighbors(point, radiusThreshold)
            if size(neighborsOfPoint)[1] > radiusThreshold # This threshold is arbitary and might need to adapt with 1. the solver, 2. the simulation
                #delete!(shocklist, point)
                #ugly way to delete point from shocklist
                i = indexin(point, shocklist)
                if isnothing(i[1])
                    continue
                else
                    i = Int(i[1])
                end
                deleteat!(shocklist, i)
                #@info point "lonely hence eliminate"
            end
        end
    end
    
    #=
    Shock points in close proximity of an obstacle (=nothing values in physical properties) are removed.
    =#
    if level < 5
        #next to borders. no shocks at obstacles.
        if data isa CellBasedEulerSim
            # We check for an arbitrary physical property of the CellSim and search for the Nothings.
            density = density_field(data, frame)
            for point in shocklist
                radiusThreshold = 2
                neighborsOfPoint = find_neighbors(point, radiusThreshold)
                n_nothing = 0

                for neighbor in neighborsOfPoint
                    xx = neighbor[1] 
                    yy = neighbor[2] 
                    
                    try
                        if isnothing(density[xx,yy])
                            n_nothing += 1
                            #@info "nothing point at" [xx,yy]
                        end
                    catch(e)
                        @warn e
                    end
                end

                if n_nothing > radiusThreshold * 1.5 # This threshold is arbitary and might need to adapt with 1. the solver, 2. the simulation
                    #ugly way to delete point from shocklist
                    i = indexin(point, shocklist)
                    if isnothing(i[1])
                        continue
                    else
                        i = Int(i[1])
                    end
                    deleteat!(shocklist, i)
                    #@info point "near osbtacle hence eliminate"
                end
            end
        end
    end

    #Construct shockwaves below.
    return shocklist
end

"""
normalVectors takes as inputs:
- frame: the frame-th step that of the simulation object that shall be processed.
- data: EulerSim{2, 4, T} object generated by Euler2D.
- shocklist: List (or vector) of 2D points where a shock is detected.
For all points in the shocklist, normalVectors detects the direction of the shock by the pressure gradient's direction, and returns a vector of 2D directions,
"""
function normalVectors(frame, data::Union{EulerSim{2,4,T}, CellBasedEulerSim{T}}, shocklist) where {T}
    p = compute_pressure_data(frame,data)
    dp = gradient_2d(frame,data,compute_pressure_data)
    shock_dir = [normalize(dp[i,j]) for (i,j) in shocklist]
    
    return shock_dir
end 

"""
findAllShocks2D takes as inputs:
- data::EulerSim{2, 4, T} object generated by Euler2D.
For all frames it detects the shock points.

"""
function findAllShocks2D(data::EulerSim{2, 4, T}; threshold = eps1_euler) where {T}
    shock_points = []
    num_frames = Euler2D.n_tsteps(data)  

    for frame in 1:num_frames
        shock = findShock2D(frame, dat; threshold = threshold)
        push!(shock_points, shock)
    end

    return shock_points
end