# ShockwaveIdentifier.jl Documentation

The Package ShockwaveIdentifier.jl enables the user to identify the position of shock waves from a grid, including the ability to: 

- Interpret a grid of Nu x Nx grid data
- Interpret a grid of Nu x Nx x nY grid data
- Finding the Normal vectors of the shockwaves at their respective shock points.

# Installation:
using Pkg
Pkg.add(PackageSpec(url="https://github.com/aramos27/ShockwaveIdentifier.jl"))

# Example usage:
For example usage please refer to the demo files inside the scripts directory. 

# Main Functions:
```@docs
load_data
findShock1D
findAllShocks1D
findShock2D
findAllShocks2D
normalVectors
plotframe1D
generate_shock_plots1D
generate_shock_plots2D
plotframe2D
```

# Additional functions found in:
# data_utils.jl:
```@docs
ShockwaveIdentifier.compute_pressure_data
ShockwaveIdentifier.compute_velocity_data
ShockwaveIdentifier.compute_density_data
ShockwaveIdentifier.normalized_velocity
ShockwaveIdentifier.compute_velocity_magnitude_data
ShockwaveIdentifier.divide_matrices
```

# plotting.jl:
```@docs
ShockwaveIdentifier.plot_bounds
ShockwaveIdentifier.plot_1d_heatmap
ShockwaveIdentifier.generateShock
```

# findShock2D.jl
```@docs
ShockwaveIdentifier.gradient_2d
ShockwaveIdentifier.delta_1p
ShockwaveIdentifier.find_zeros!
ShockwaveIdentifier.delta_2p
ShockwaveIdentifier.blank
ShockwaveIdentifier.find_neighbors
ShockwaveIdentifier.update_shocklist_refined
ShockwaveIdentifier.remove_lonely_points!

```