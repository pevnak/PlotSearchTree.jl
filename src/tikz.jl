
"""
dt = function depth(st::SearchTree)

create a map of nodes to their depth in search tree

```julia	
julia> dt = depth(st)
Dict{UInt64, Int64} with 7 entries:
  0x9d346f48836060c5 => 0
  0x239772ea48f56dd5 => 1
  0xd6f72130b34ab51a => 1
  0x34210d401741745b => 2
  0x097fd218ea0f517a => 2
  0xa8eb4cb52221b2ae => 2
  0xd5dff6d6dad04750 => 3
```

"""
function depth(st::SearchTree)
	dt = Dict{UInt64, Int64}()
	for s in keys(st)
		updatedepth!(dt, st, s)
	end
	dt
end

function updatedepth!(dt, st, s)
	haskey(dt, s) && return(dt[s])
	node = st[s]
	if node.parent.id == s
		dt[s] = 0 
	else
		dt[s] = updatedepth!(dt, st, node.parent.id) + 1
	end
end

"""
dt, layers = treelayers(search_tree)

Create map of nodes in `search_tree` to their depth in them.
Organize nodes into layers, such that each layer contain nodes of a single depth.

"""
function treelayers(st)
	dt = depth(st)
	max_depth = maximum(values(dt))
	max_width = maximum(values(countmap(values(dt))))
	nodeids = collect(keys(dt))

	layers = Vector{Vector{UInt64}}()
	# plot root node
	root_node = only(filter(k -> dt[k] == 0, nodeids))
	push!(layers, [root_node])

	parent_positions = Dict(root_node => 0)
	for d in 1:max_depth
		childs = collect(filter(k -> dt[k] == d, nodeids))
		pp = [parent_positions[st[k].parent.id] for k in childs]
		childs = childs[sortperm(pp)]
		parent_positions = Dict(reverse.(enumerate(childs)))
		push!(layers, childs)
	end
	dt, layers
end


"""
struct EvalTracker{H<:Heuristic} <: Heuristic 
	heuristic::H
	order::Dict{UInt64,Int}
	vals::Dict{UInt64,Float64}
end

A wraper around the heuristic logging the order at which the state was evaluated first time and its value. 


"""
struct EvalTracker{H<:Heuristic} <: Heuristic 
	heuristic::H
	order::Dict{UInt64,Int}
	vals::Dict{UInt64,Float64}
end

EvalTracker(heuristic) = EvalTracker(heuristic, Dict{UInt64,Int}(), Dict{UInt64,Float64}())

#reexport the heuristic api
Base.hash(g::EvalTracker, h::UInt) = hash(g.model, hash(g.pddle, h))

function SymbolicPlanners.compute(h::EvalTracker, domain::Domain, state::State, spec::Specification)
	id = hash(state)
	get!(h.order, id, length(h.order) + 1)
	get!(h.vals, id, SymbolicPlanners.compute(h.heuristic, domain, state, spec))
end

SymbolicPlanners.precompute!(h::EvalTracker, domain::Domain, state::State, spec::Specification) = SymbolicPlanners.precompute!(h.heuristic, domain, state, spec)
# SymbolicPlanners.ensure_precompute!(h::EvalTracker, args) = SymbolicPlanners.ensure_precompute!(h.heuristic, args)
# SymbolicPlanners.is_precomputed!(h::EvalTracker) = SymbolicPlanners.is_precomputed!(h.heuristic)

preamble = """
\\documentclass{standalone}
\\usepackage{tikz}
\\usepackage{verbatim}
\\usepackage{adjustbox}
\\usetikzlibrary{arrows,shapes}


\\begin{document}

\\tikzstyle{nonoptimalnode}=[circle,fill=black!25,minimum size=20pt,inner sep=0pt]
\\tikzstyle{optimalnode} = [nonoptimalnode, fill=red!24]
\\tikzstyle{nonoptimaledge} = [draw,->,thin]
\\tikzstyle{optimaledge} = [draw,thick,->]
\\tikzstyle{hiddennode} = [white]
\\tikzstyle{hiddenedge} = [white]
\\begin{tikzpicture}
"""

closing = """
\\end{tikzpicture}
\\end{document}
"""

"""
plot_search_tree(io::IOStream, st, trajectory; α = 1, β = 1, hspace = 1, vspace = 1, kwargs...)
plot_search_tree(io::IOStream, st, trajectory, hvals; α = 1, β = 1, hspace = 1, vspace = 1, kwargs...)
plot_search_tree(filename::String, st, trajectory, hvals; α = 1, β = 1, hspace = 1, vspace = 1, kwargs...)
plot_search_tree(filename::String, st, trajectory, hvals; α = 1, β = 1, hspace = 1, vspace = 1, kwargs...)
plot_search_tree(filename::String, sol::PathSearchSolution, he::EvalTracker; α = 1, β = 1, hspace = 1, vspace = 1, kwargs...)

Create a latex document visualizing search tree using tikz library.
Nodes on `trajectory` are highlighted in pink. 
If hvals are supplied, then the nodes contains the heuristic value `f = αg + βh,`
where `g` is the path cost and `h` is a heuristic value. With default setting 
`α = β = 1`, nodes contains value as A* sees it. 
`hspace` and `vspace` is the multiplier controlling horizontal and vertical spacing of nodes 
"""
function plot_search_tree(io::IOStream, st::SearchTree, trajectory, hvals = Dict{UInt64, Float64}(); α = 1, β = 1, hspace = 1, vspace = 1, hidden::Set{UInt64} = Set{UInt64}(), kwargs...)
	dt, layers = treelayers(st)
	println(io, preamble)
	for (row, states) in enumerate(layers)
		offset = div(length(states),2)
		for (col, state) in enumerate(states)
			pos = "($((col - offset)*hspace) ,- $(row*vspace))"
			label = "node$(state)"
			style = state ∈ trajectory ? "optimal" : "nonoptimal"
			style = state ∈ hidden ? "hidden" : style
			f = β * get(hvals, state, 0) + α* st[state].path_cost
			f = round(f, digits = 2)
			println(io, "\\node[$(style)node] ($label) at $(pos) {$(f)};")
			pid = st[state].parent.id
			if pid !== nothing 
				println(io, "\\path[$(style)edge] (node$(pid).south) -- ($label.north);")
			end
		end
	end
	println(io, closing)
end

function plot_search_tree(filename::String, st::SearchTree, trajectory, hvals = Dict{UInt64, Float64}(); kwargs...)
	open(io -> plot_search_tree(io, st, trajectory, hvals; kwargs...), filename, "w")
end

function plot_search_tree(filename::String, sol::PathSearchSolution, he::EvalTracker; kwargs...)
	open(io -> plot_search_tree(io, sol.search_tree, hash.(sol.trajectory), he.vals; kwargs...), filename, "w")
end
