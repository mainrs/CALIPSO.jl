@testset "Objective" begin
    T = 3
    num_state = 2
    num_action = 1 
    num_parameter = 0
    ot = (x, u, w) -> dot(x, x) + 0.1 * dot(u, u)
    oT = (x, u, w) -> 10.0 * dot(x, x)
    ct = Cost(ot, num_state, num_action, num_parameter=num_parameter)
    cT = Cost(oT, num_state, 0, num_parameter=num_parameter)
    objective = [[ct for t = 1:T-1]..., cT]

    J = [0.0]
    gradient = zeros((T - 1) * (num_state + num_action) + num_state)
    idx_xu = [collect((t - 1) * (num_state + num_action) .+ (1:(num_state + (t == T ? 0 : num_action)))) for t = 1:T]
    x1 = ones(num_state) 
    u1 = ones(num_action)
    w1 = zeros(num_parameter) 
    X = [x1 for t = 1:T]
    U = [t < T ? u1 : zeros(0) for t = 1:T]
    W = [w1 for t = 1:T]

    ct.cost(ct.cost_cache, x1, u1, w1)
    ct.gradient_variables(ct.gradient_variables_cache, x1, u1, w1)
    @test ct.cost_cache[1] ≈ ot(x1, u1, w1)
    @test norm(ct.gradient_variables_cache - [2.0 * x1; 0.2 * u1]) < 1.0e-8

    cT.cost(cT.cost_cache, x1, u1, w1)
    cT.gradient_variables(cT.gradient_variables_cache, x1, u1, w1)
    @test cT.cost_cache[1] ≈ oT(x1, u1, w1)
    @test norm(cT.gradient_variables_cache - 20.0 * x1) < 1.0e-8

    cc = zeros(1)
    CALIPSO.cost(cc, objective, X, U, X)
    @test cc[1] - sum([ot(X[t], U[t], W[t]) for t = 1:T-1]) - oT(X[T], U[T], W[T]) ≈ 0.0
    CALIPSO.gradient_variables!(gradient, idx_xu, objective, X, U, W) 
    @test norm(gradient - vcat([[2.0 * x1; 0.2 * u1] for t = 1:T-1]..., 20.0 * x1)) < 1.0e-8

    # info = @benchmark CALIPSO.cost($objective, $X, $U, $W)
    # info = @benchmark CALIPSO.gradient!($gradient, $idx_xu, $objective, $X, $U, $W)
end
