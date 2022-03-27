# dimensions 
num_variables = 10 
num_equality = 5 
num_inequality = 5

x = randn(num_variables)
s = rand(num_inequality)
y = randn(num_equality)
z = randn(num_inequality)
t = rand(num_inequality) 

w = [x; s; y; z; t]
κ = [1.0]
ρ = [1.0e6]
λ = zeros(num_equality)
ϵp = 1.0e-5 
ϵd = 1.0e-6 


# methods
objective, equality, inequality, flag = generate_random_qp(num_variables, num_equality, num_inequality);

# solver
methods = ProblemMethods(num_variables, objective, equality, inequality)
solver = Solver(methods, num_variables, num_equality, num_inequality)

problem!(solver.problem, solver.methods, solver.indices, w)

matrix!(solver.data, solver.problem, solver.indices, w, κ, ρ, λ)

matrix_symmetric!(solver.data.matrix_symmetric, solver.data.matrix, solver.indices)

residual!(solver.data, solver.problem, solver.indices, w, κ, ρ, λ)

residual_symmetric!(solver.data.residual_symmetric, solver.data.residual, solver.data.matrix, solver.indices)

# KKT matrix 
@test rank(solver.data.matrix) == solver.dimensions.total
@test norm(solver.data.matrix[solver.indices.variables, solver.indices.variables] - (solver.problem.objective_hessian + solver.problem.equality_hessian + solver.problem.inequality_hessian)) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.equality, solver.indices.variables] - solver.problem.equality_jacobian) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.variables, solver.indices.equality] - solver.problem.equality_jacobian') < 1.0e-6
@test norm(solver.data.matrix[solver.indices.equality, solver.indices.equality] + 1.0 / ρ[1] * I(num_equality)) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.inequality, solver.indices.variables] - solver.problem.inequality_jacobian) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.variables, solver.indices.inequality] - solver.problem.inequality_jacobian') < 1.0e-6
@test norm(solver.data.matrix[solver.indices.slack_primal, solver.indices.inequality] + I(num_inequality)) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.inequality, solver.indices.slack_primal] + I(num_inequality)) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.slack_primal, solver.indices.slack_dual] + I(num_inequality)) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.slack_dual, solver.indices.slack_primal] - Diagonal(w[solver.indices.slack_dual])) < 1.0e-6
@test norm(solver.data.matrix[solver.indices.slack_dual, solver.indices.slack_dual] - Diagonal(w[solver.indices.slack_primal])) < 1.0e-6

# KKT matrix (symmetric)
@test rank(solver.data.matrix_symmetric) == solver.dimensions.symmetric
@test norm(solver.data.matrix_symmetric[solver.indices.variables, solver.indices.variables] - (solver.problem.objective_hessian + solver.problem.equality_hessian + solver.problem.inequality_hessian)) < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.symmetric_equality, solver.indices.variables] - solver.problem.equality_jacobian) < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.variables, solver.indices.symmetric_equality] - solver.problem.equality_jacobian') < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.symmetric_equality, solver.indices.symmetric_equality] + 1.0 / ρ[1] * I(num_equality)) < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.symmetric_inequality, solver.indices.variables] - solver.problem.inequality_jacobian) < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.variables, solver.indices.symmetric_inequality] - solver.problem.inequality_jacobian') < 1.0e-6
@test norm(solver.data.matrix_symmetric[solver.indices.symmetric_inequality, solver.indices.symmetric_inequality] + Diagonal(w[solver.indices.slack_primal] ./ w[solver.indices.slack_dual])) < 1.0e-6

# residual 
@test norm(solver.data.residual[solver.indices.variables] - (solver.problem.objective_gradient + solver.problem.equality_jacobian' * w[solver.indices.equality] + solver.problem.inequality_jacobian' * w[solver.indices.inequality])) < 1.0e-6
@test norm(solver.data.residual[solver.indices.equality] - (solver.problem.equality - 1.0 / ρ[1] * (λ - w[solver.indices.equality]))) < 1.0e-6
@test norm(solver.data.residual[solver.indices.inequality] - (solver.problem.inequality - w[solver.indices.slack_primal])) < 1.0e-6
@test norm(solver.data.residual[solver.indices.slack_primal] - (-w[solver.indices.inequality] - w[solver.indices.slack_dual])) < 1.0e-6
@test norm(solver.data.residual[solver.indices.slack_dual] - (w[solver.indices.slack_primal] .* w[solver.indices.slack_dual] .- κ[1])) < 1.0e-6

# residual symmetric
@test norm(solver.data.residual_symmetric[solver.indices.variables] - (solver.problem.objective_gradient + solver.problem.equality_jacobian' * w[solver.indices.equality] + solver.problem.inequality_jacobian' * w[solver.indices.inequality])) < 1.0e-6
@test norm(solver.data.residual_symmetric[solver.indices.symmetric_equality] - (solver.problem.equality - 1.0 / ρ[1] * (λ - w[solver.indices.equality]))) < 1.0e-6
@test norm(solver.data.residual_symmetric[solver.indices.symmetric_inequality] - (solver.problem.inequality - w[solver.indices.slack_primal] - w[solver.indices.slack_primal] .* w[solver.indices.inequality] ./ w[solver.indices.slack_dual] - κ[1] * ones(num_inequality) ./ w[solver.indices.slack_dual])) < 1.0e-6

# step
fill!(solver.data.residual, 0.0)
residual!(solver.data, solver.problem, solver.indices, w, κ, ρ, λ)
step!(solver.data.step, solver.data)
Δ = deepcopy(solver.data.step)

step_symmetric!(solver.data.step, solver.data.residual, solver.data.matrix, 
    solver.data.step_symmetric, solver.data.residual_symmetric, solver.data.matrix_symmetric, 
    solver.indices, solver.linear_solver)
Δ_symmetric = deepcopy(solver.data.step)

@test norm(Δ - Δ_symmetric) < 1.0e-6

# iterative refinement
noisy_step = solver.data.step + randn(length(solver.data.step))
iterative_refinement!(noisy_step, solver)
@test norm(solver.data.residual - solver.data.matrix * noisy_step) < solver.options.iterative_refinement_tolerance
