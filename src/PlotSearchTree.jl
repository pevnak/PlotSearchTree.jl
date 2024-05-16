module PlotSearchTree

using PDDL, SymbolicPlanners, StatsBase, Printf

SearchTree{N} = Dict{UInt64, N} where {N<:SymbolicPlanners.PathNode}

include("tikz.jl")
include("animate.jl")
# include("glmakie.jl")

export EvalTracker, plot_search_tree, animate_search_tree
end # module PlotSearchTree
