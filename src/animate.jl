
# let's try animation
# we need to group states by parents

"""
	group_states(st::SearchTree, h::EvalTracker)

	Group states and sort them in order they have been expanded. Useful for animation of the search.

```julia
julia> group_states(st, h)
17-element Vector{Vector{UInt64}}:
 [0x832612ab240fd76d, 0x13d1d03e2c34ede9, 0x3153dca2348b434d, 0x71fbb475150b544c]
 [0xb9f34369f88d4bcf, 0xd6df5352c5ce4b57, 0xc4a7f6d8c76ca879]
 [0xd7f9efc6bd7560ea, 0xd23ea1b8348c7eec, 0x993a79d59ffd5521]
 [0x8729ebc221c3a3d6, 0x791f21115b760992]
 [0xea8c326ae400ae49, 0x67b6d7aa8ba4a0df]
 [0x5f1b93a8531e232c, 0x341ec16f516c0dd0, 0x20c4abc3351ac8b2, 0x73b186503df469e4]
 [0x2b4104ca9d6db0d4, 0xac60142c65dc1258, 0xadaee8a938ac08d0]
 [0x604e414a00fbde87, 0x0fa271360ce604a2, 0x486bf10ca066d591]
 [0xfe35191771dcd316, 0x4880428357b875c2]
 [0xd9ae73c3b1d139e4, 0x002462e8af7c23a0, 0xecc82db3970a364e, 0xa52ad16cc431be97]
 [0x4bb6eff4ebbb930a, 0x923c3094557449b0]
 [0xe7b225d64ef6714c, 0xa1e0c25d003bfd24, 0x43f1355e38ddd395]
 [0x75278779c3e64761, 0x7302ca6125b0f316]
 [0x168e1d78ce2856d7, 0x95db1fa4855f8518]
 [0x11f5888dcd6b94a8, 0x431968caf27ba178]
 [0xd916f516c806723e]
 [0x6a99c5d2c1b1e123]
```
"""
function group_states(st::SearchTree, h::EvalTracker)
	ordered_state = sort([(;order = v, parent_id = st[k].parent.id, id = k) for (k, v) in h.order])
	groups = UnitRange[]
	start = 1
	while start ≤ length(ordered_state)
		stop = start
		while (stop ≤ length(ordered_state)) && (ordered_state[start].parent_id == ordered_state[stop].parent_id)
			stop += 1 
		end
		push!(groups, start:stop-1)
		start = stop
	end
	map(groups) do span 
		[ordered_state[j].id for j in span]
	end
end

"""
	animate_search_tree(output_file, sol, h::EvalTracker; convert_path="/opt/homebrew/bin/convert", pdflatex="pdflatex", name_prefix="search_tree",  delete_pdf = true, delete_tex = true, delete_pngs = true, offset = 0, kwargs...)

	Create an animation of how states in the searchtree are expanded, which is nice to demonstrate when things can go sour.
	The function relies on external commands `pdflatex` and `convert`. Path to them can be set by `convert_path` and `pdflatex`. 
	Name of the intermediate files can be set by `name_prefix`.
	When making the animation, the function creates a large bunch of intermediate files, `tex`, `pdf`, and `png`. 
	If you want to retain some of them, set `save_tex=true` or appropriate alternative.
	`kwargs` are passed to `animate_search_tree` used to plot the searchtree.		
"""

function animate_search_tree(output_file, sol, h::EvalTracker; convert_path="convert", pdflatex="pdflatex", name_prefix="search_tree",  delete_pdf = true, delete_tex = true, delete_pngs = true, offset = 0, kwargs...)
	# endswith(output_file, ".gif") || error("output_file has to end with .gif")
	hidden = Set(keys(sol.search_tree))
	groups = group_states(sol.search_tree, h)
	for (i, new_states) in enumerate(groups)
		hidden = setdiff(hidden, new_states)
		name = @sprintf("%s_%03d", name_prefix, i + offset)
		plot_search_tree(name*".tex", sol, h; hidden, kwargs...)
		run(`pdflatex $name.tex`)
		run(`/opt/homebrew/bin/convert -background white -alpha remove -alpha off -density 300 $name.pdf $name.png`)
		delete_pdf && rm(name*".pdf")
		delete_tex && rm(name*".tex")
		rm(name*".log")
		rm(name*".aux")
	end

	run(`/opt/homebrew/bin/convert -delay 100 -loop 0 $(name_prefix)_'*'.png $output_file`)
	if delete_pngs
		for i in 1:length(groups)
			name = @sprintf("%s_%03d", name_prefix, i + offset)
			rm(name*".png")
		end
	end
end