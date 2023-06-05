using Makie



"""
node_layout(layers::Vector{Vector{UInt64}})
node_layout(dt::Dict{UInt64, Int64}, layers::Vector{Vector{UInt64}})
node_layout(st::Dict{UInt64, <:SymbolicPlanners.PathNode})


create a dictionary state => (x,y) position of the node. 
"""
function node_layout(layers::Vector{Vector{UInt64}})
	nl = Dict{UInt64,NTuple{2,Float64}}()
	for (row, states) in enumerate(layers)
		offset = div(length(states),2)
		for (col, state) in enumerate(states)
			nl[state] = (col - offset, -row)
		end
	end
	nl
end

function node_layout(dt::Dict{UInt64, Int64}, layers::Vector{Vector{UInt64}})
	node_layout(layers)
end

function node_layout(st::Dict{UInt64, <:SymbolicPlanners.PathNode})
	dt, layers = treelayers(st)
	node_layout(dt, layers)
end



function array_coords(x, y, u, v)
	[x y u - x v - y]
end

function plot_search_tree(sol::PathSearchSolution ;markersize = 20)
	nl = node_layout(sol.search_tree)

	kv = collect(nl)
	path = Set(hash.(sol.trajectory))
	x = [x[2][1] for x in kv]
	y = [x[2][2] for x in kv]
	c = [x[1] ∈ path ? :orange : :blue for x in kv]
	ac = reduce(vcat, [array_coords(nl[s.id]..., nl[s.parent_id]...) for s in values(sol.search_tree) if s.parent_id !== nothing])

	fig = scatter(x, y; markersize, color = c);
	arrows!([ac[:,i] for i in 1:4]...; linecolor = :gray, arrowcolor = :black)
	fig
end

