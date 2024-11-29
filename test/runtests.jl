using ShockwaveIdentifier
using Test

temp_dir = "../tmp"
@testset "ShockwaveIdentifier.jl" begin
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
    @testset "Run test 1D" begin
        include("../scripts/demo_full_1d.jl")
    end

    @testset "Run test 2D (array)" begin
        include("../scripts/demo_orb_2d.jl")
    end

    @testset "Run test 2D (cells)" begin
        include("../scripts/demo_celltape.jl")
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

@testset "Sod 2D Detection Test" begin
    tapes = [
    "../dataSim/sod_shock_right_2d.tape"
    ]

    for tape in tapes
        println("Processing $tape")
        data = load_data(tape)
        save_dir = temp_dir
        for t in data.nsteps
            if t != 0.
                shocklist = shockwave_algorithm(t, data, level=1, threshold = 1.25)
                @test length(shocklist) >= 10
                @test length(shocklist) <= 30
            end
        end
        generate_shock_plots2D(load_data(tape), )
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
