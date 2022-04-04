# solver 
function initialize!(solver::Solver, guess)
    # variables 
    solver.variables[solver.indices.variables] = guess 
    return
end

function initialize_slacks!(solver)
    # set slacks to constraints
    problem!(solver.problem, solver.methods, solver.indices, solver.variables,
        gradient=false,
        constraint=true,
        jacobian=false,
        hessian=false)

    for (i, idx) in enumerate(solver.indices.equality_slack)
        solver.variables[idx] = solver.problem.equality[i]
    end

    for (i, idx) in enumerate(solver.indices.inequality_slack)
        solver.variables[idx] = max(1.0, solver.problem.inequality[i]) 
    end

    return 
end

function initialize_duals!(solver)
    solver.variables[solver.indices.equality_dual] .= 0.0
    solver.variables[solver.indices.inequality_dual] .= 0.0
    solver.variables[solver.indices.inequality_slack_dual] .= 1.0 
    return 
end

function initialize_interior_point!(central_path, options::Options)
    central_path[1] = options.central_path_initial
    return 
end

function initialize_augmented_lagrangian!(penalty, dual, options::Options)
    penalty[1] = options.penalty_initial 
    dual .= options.dual_initial
    return 
end