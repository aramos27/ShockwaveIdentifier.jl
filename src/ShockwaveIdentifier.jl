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

export findShock1D
export findShock2D
export normalVectors


end
