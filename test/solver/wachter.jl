@testset "Solver problem: Wachter" begin
    num_variables = 3
    num_equality = 2
    num_inequality = 2
    x0 = [-2.0, 3.0, 1.0]

    obj(x) = x[1]
    eq(x) = [x[1]^2 - x[2] - 1.0; x[1] - x[3] - 0.5]
    ineq(x) = x[2:3]

    # solver
    methods = ProblemMethods(num_variables, obj, eq, ineq)
    solver = Solver(methods, num_variables, num_equality, num_inequality)
    initialize!(solver, x0)

    # solve 
    solve!(solver)

    @test norm(solver.data.residual, Inf) < 1.0e-5
    @test norm(solver.variables[1:3] - [1.0; 0.0; 0.5], Inf) < 1.0e-5
end