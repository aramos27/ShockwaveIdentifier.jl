using ShockwaveIdentifier
using Test

temp_dir = "../tmp"
@testset "ShockwaveIdentifier.jl" begin
    # (Pre-)Compilation Test
    using ShockwaveIdentifier
end

@testset "Load tape files" begin
#array sims
    #1d tape
    load_data("../dataSim/supersonic_shock_2.tape")
    #2d tape
    load_data("../dataSim/sod_shock_right_2d.tape")
#cell sims
    #2d celltape
    load_data("../dataSim/funky_triangle.celltape")
end

@testset "Supersonic 1D Test" begin
    tapes = [
    "../dataSim/supersonic_shock_3.tape"
    ]

    for tape in tapes
        println("Processing $tape")
        generate_shock_plots1D(load_data(tape), save_dir = temp_dir)
    end

    rm(temp_dir)
end

@testset "Sod orb 2D Test" begin
    tapes = [
    "../dataSim/sod_shock_orb.tape"
    ]

    for tape in tapes
        println("Processing $tape")
        generate_shock_plots2D(load_data(tape), save_dir = temp_dir)
    end

    rm(temp_dir)
end

@testset "Celltape 2D Test" begin
    tapes = [
    "../dataSim/funky_triangle.tape"
    ]

    for tape in tapes
        println("Processing $tape")
        generate_shock_plots2D(load_data(tape), save_dir = temp_dir)
    end

    rm(temp_dir)
end
