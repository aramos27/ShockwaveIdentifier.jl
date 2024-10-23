### ShockwaveIdentifier.jl Documentation

The Package ShockwaveIdentifier.jl enables the user to identify shockwaves from CFD simulations of the [Euler2D](https://github.com/STCE-at-RWTH/Euler2D.jl) package, by: 

- Analyzing physical properties (such as density, pressure, etc.) on a one-dimensional spatial grid over time
- Analyzing physical properties (such as density, pressure, etc.) on a two-dimensional spatial grid over time
- Finding the normal vectors of the shockwaves at their respective shock points.

## Installation:
Execute in REPL:
using Pkg
Pkg.add(PackageSpec(url="https://github.com/aramos27/ShockwaveIdentifier.jl"))

## Example usage:
For example usage, please refer to the demo files inside the scripts directory, as well as the Pluto notebooks inside the notebooks directory.

## Main (Exported) Functions:
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

## Additional functions found in:
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