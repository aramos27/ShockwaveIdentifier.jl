# docs/make.jl
using Documenter
using ShockwaveIdentifier

makedocs(
    sitename = "ShockwaveIdentifier.jl Documentation",  # Name of your documentation
    modules = [ShockwaveIdentifier],                    # The module to document
    format = Documenter.HTML(),                         # Output format (HTML)
    pages = [
        "Home" => "index.md",                           # Main documentation page
    ]
)

deploydocs(
    repo = "github.com/aramos27/ShockwaveIdentifier.jl",  # GitHub repository URL
)