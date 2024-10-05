using ShockwaveIdentifier

#Enter all tape files as command line arguments
for tape in ARGS
    #try
        println("Processing $tape")
        generate_shock_plots1D(load_data(tape))
    #catch e 
        @error e 
    #end
end

