#IMPORTANT find out how to use it directly from ShockwaveProperties without redefining
const DRY_AIR = CaloricallyPerfectGas(1004.9u"J/kg/K", 717.8u"J/kg/K", 0.0289647u"kg/mol")

#=Returns matrix containing a vector (∂ρ/∂x, ∂ρ/∂y) at each point
 Function to compute the gradient, accounting for mesh grid sizes hx and hy
=#
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

#Calls gradient_2d after formatting data accordingly
function gradient_2d(frame, data::EulerSim{2,4,T}, compute_data_function) where {T}

    # Check if the data is an EulerSim or a regular Float64 array
    if typeof(data) <: EulerSim
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


 #=
    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
=#
function delta_1p(frame, data::EulerSim{2,4,T}) where {T}
    #IMPORTANT, ARE THESE VARIABLES NEEDED??
    x_width = last(cell_centers(data)[1]) - cell_centers(data)[1][1]
    y_width = last(cell_centers(data)[2]) - cell_centers(data)[2][1]

    #factor l as the area of computation / computational domain in 2D

    #because the other option (x*y) turns out to be quite large, we will try the grid size instead.
    #state of 10.09.2024: It seems to work.
    l = cell_centers(data)[2][2] - cell_centers(data)[2][1]

    ρ = compute_density_data(frame, data)
    ρ = ustrip(ρ)

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

#=
Serves the purpose of finding zeros in discretized data such as d1p and d2p through sign changes. 
    Wherever a sign change occurs, the values are replaced with 0.
=#
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
        
        # Efficient handling for 2D array
        for i in 1:rows
            for j in 2:cols
                if signbit(discret[i, j]) != signbit(discret[i, j-1])
                    if discret[i, j] != 0 && discret[i, j-1] != 0
                        discret[i, j] = 0
                        discret[i, j-1] = 0
                    end
                end
            end
        end

        for j in 1:cols
            for i in 2:rows
                if signbit(discret[i, j]) != signbit(discret[i-1, j])
                    if discret[i, j] != 0 && discret[i-1, j] != 0
                        discret[i, j] = 0
                        discret[i-1, j] = 0
                    end
                end
            end
        end
    else
        error("Input must be either a 1D or 2D array.")
    end
    return 
end





"""
Turns 0 for shocks. Presumably, when the density gradient is also not zero.

    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
"""
function delta_2p(frame, data::EulerSim{2,4,T}) where {T}
 

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
Faster when d1p is precomputed, taking d1p already into account. 
optional argument d1p shall be a Matrix{T}

Turns 0 for shocks. Presumably, when the density gradient is also not zero.

    Calculate the piecewise dot-product of the normalized velocity and the gradient of the density data. According to the paper "Accurate detection of shock waves and shock interactions in two-dimensional shock-capturing solutions.pdf"
"""
function delta_2p(frame, data::EulerSim{2,4,T}, d1p::Matrix{T}) where {T}
 

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

"""blanking part:
wherever d2p == 0 and d1p != 0. Works abit besides of initial false-positive detection of expansion waves.

Needs d1p and d2p as arguments and finds the nul-points of d2p as possible extremals of d1p, and thus shockwaves. To eliminate the rest, only candidates with a d1p value above a certain threshold remain considered.

TODO :
Find eps1, eps2 so that it works. Possible, eps1 will have to depend on the intensity of shockwave. eps2 is set to take into account floating point arithmetic errors.

"""
function blank(d1p::Matrix{T}, d2p::Matrix{T}, eps1::T = 0.1, eps2::T = 10e-4) where {T<:Number}
    # Create a blank matrix of the same size as the input matrices
    blanked = zeros(T, size(d1p)) 

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
                    blanked[i, j] = 1
                    
                    shock_counter += 1
                    #println("Shock with d1p $(d1p[i,j]) and d2p $(d2p[i,j]) at $i $j")
                else
                    #println("Potential Shock with d1p $(d1p[i,j]) and d2p $(d2p[i,j]) at $i $j") 
                end
            else
                blanked[i, j] = 0
            end
        end
    end

    println("Number of shockwaves detected: $shock_counter")
    return blanked
end

#Finds all possible shockpoints and returns a list of their coordinates. 
function findShock2D(frame, data::EulerSim{2,4,T}) where {T}
    d1p = delta_1p(frame, data);
    d2p = delta_2p(frame, data, d1p);
    blanked = blank(d1p, d2p, 0.15, 10e-5);

    blanked_bool = falses(size(blanked))
    blanked_bool .= blanked .> 0 

    shocklist = []
    for i in 1:size(blanked_bool, 1)
        for j in 1:size(blanked_bool, 2)
            if blanked_bool[i, j] == true
                push!(shocklist, (i, j))
            end
        end
    end
    return shocklist
end 

