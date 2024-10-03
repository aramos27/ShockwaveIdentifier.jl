module ShockwaveIdentifier

using Euler2D
using LaTeXStrings
using LinearAlgebra
using Plots
using Printf
using ShockwaveProperties
using Tullio
using Unitful
using Dates
using Images

using StaticArrays

include("shock1D.jl")
include("shock2D.jl")

include("plotting.jl")
include("data_utils.jl")

export load_sim_data
export load_data

export findShock1D
export findAllShocks1D
export findShock2D
export normalVectors

export plotframe1D
export plot_bounds
export plotframe2D


end
