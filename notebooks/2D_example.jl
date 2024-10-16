### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 1b7ead20-2f14-11ef-28d1-03ad74bf304a
begin
	import Pkg
	Pkg.activate()
	using Euler2D
	using LaTeXStrings
	using LinearAlgebra
	using Plots
	using PlutoUI
	using Printf
	using ShockwaveProperties
	using StaticArrays
	using Unitful
	using ShockwaveIdentifier
end

# ╔═╡ 1b1c0430-bacf-454a-a0bf-b00c7b723b48
begin
	#Tape file location
	tape = "../dataSim/circular_obstacle_radius_1.celltape";
	#import tape file as data object
	data = load_data(tape);
end

# ╔═╡ 55c06a26-bc2e-45f4-bb6f-68e1f000aa57
@bind frame Slider(1:n_tsteps(data); show_value=true)

# ╔═╡ 7662186d-97ec-46b5-b0f7-37f29bd31305
fig_ = plotframe2D(frame, data, ShockwaveIdentifier.compute_density_data, findShock2D; vectors=true, threshold = 0.2, level = 2) 

# ╔═╡ 5190ba18-858a-4937-bc98-adddd8e110f8


# ╔═╡ Cell order:
# ╠═1b7ead20-2f14-11ef-28d1-03ad74bf304a
# ╠═1b1c0430-bacf-454a-a0bf-b00c7b723b48
# ╠═55c06a26-bc2e-45f4-bb6f-68e1f000aa57
# ╠═7662186d-97ec-46b5-b0f7-37f29bd31305
# ╠═5190ba18-858a-4937-bc98-adddd8e110f8
