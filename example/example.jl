using PDDL, PlanningDomains, SymbolicPlanners, PlotSearchTree

# Load Blocksworld domain and problem
domain = load_domain(:blocksworld)
problem = load_problem(:blocksworld, "problem-4")

# Construct initial state from domain and problem
state = initstate(domain, problem)

# Construct goal specification that requires minimizing plan length
spec = MinStepsGoal(problem)

# Construct A* planner with h_add heuristic
h = EvalTracker(HAdd())
planner = AStarPlanner(h;save_search = true)

# Find a solution given the initial state and specification
sol = planner(domain, state, spec)
plot_search_tree("blocksworld.tex", sol, h)


