using ShockwaveIdentifier
using Test

temp_dir = "../tmp"
@testset "ShockwaveIdentifier.jl" begin
    if !isdir("frames/")
        mkdir("frames/")
    end
    @testset "Compilation Test" begin
        # (Pre-)Compilation Test: Are all (important) functions existing?
        using ShockwaveIdentifier
        @test findShock1D isa Function
        @test findShock1D isa Function

        @test normalVectors isa Function

        @test plotframe1D isa Function
        @test plotframe2D isa Function
        @test generate_shock_plots1D isa Function
        @test generate_shock_plots2D isa Function
        end

    @testset "Load/Import test" begin
        # Test whether tapes can be loaded (and are at the right place)
        using Euler2D
        @test load_data("../dataSim/funky_square.celltape") isa CellBasedEulerSim
        @test load_data("../dataSim/sod_shock_left_1d.tape") isa EulerSim
    end

    @testset "Shock detection tests" begin 
        include("shorttests.jl")
    end

    @testset "Plot tests" begin
        include("plottests.jl")
    end

    if ispath("frames/")
        rm("frames/")
    end
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
