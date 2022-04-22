# solver 
function initialize!(solver::Solver, guess)
    # variables 
    solver.variables[solver.indices.variables] = guess 
    return
end

function initialize_slacks!(solver)
    # set slacks to constraints
    problem!(solver.problem, solver.methods, solver.indices, solver.variables, solver.parameters,
        equality_constraint=true,
        cone_constraint=true,
    )

    for (i, idx) in enumerate(solver.indices.equality_slack)
        solver.variables[idx] = solver.problem.equality_constraint[i]
    end

    s = @view solver.variables[solver.indices.cone_slack]
    initialize_cone!(s, solver.indices.cone_nonnegative, solver.indices.cone_second_order) 

    return 
end

function initialize_duals!(solver)
    solver.variables[solver.indices.equality_dual] .= 0.0
    solver.variables[solver.indices.cone_dual] .= 0.0
    t = @view solver.variables[solver.indices.cone_slack_dual]
    initialize_cone!(t, solver.indices.cone_nonnegative, solver.indices.cone_second_order) 
    return 
end

function initialize_interior_point!(solver)
    solver.central_path[1] = solver.options.central_path_initial
    solver.fraction_to_boundary[1] = max(0.99, 1.0 - solver.central_path[1])
    return 
end

function initialize_augmented_lagrangian!(solver)
    solver.penalty[1] = solver.options.penalty_initial 
    solver.dual .= solver.options.dual_initial
    return 
end
