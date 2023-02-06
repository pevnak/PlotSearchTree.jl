# Plot search tree 
is a simple convenience package to visualize the search tree of Forward search algorithm.

The use is straightforward.
```julia
using Test, Random
using PDDL, PlanningDomains
using SymbolicPlanners
using PlotSearchTree 


domain = load_domain(:gridworld)
problem = load_problem(:gridworld, "problem-1")
state = initstate(domain, problem)
spec = Specification(problem)


h = EvalTracker(HAdd())
planner = AStarPlanner(h; max_time=3600, save_search = true)
sol = planner(domain, state, spec)

plot_search_tree("/tmp/debug.tex", sol, h)
```
where `EvalTracker` wraps the heuristic to save its values and order at which states were evaluated. 
`plot_search_tree` than saves the plot in latex tikz format which needs to be compiled manually. See
help for options.