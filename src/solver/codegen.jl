function generate_gradients(func::Function, num_variables::Int, num_parameters::Int, mode::Symbol;
    checkbounds=false,
    threads=false)
    @variables x[1:num_variables] θ[1:num_parameters]
    # x = Symbolics.variables(:x, 1:num_variables)
    # θ = Symbolics.variables(:θ, 1:num_parameters)

    if mode == :scalar 
        f = [func(x, θ)]
        
        fx = Symbolics.gradient(f[1], x)
        fθ = Symbolics.gradient(f[1], θ)
        fxx = Symbolics.jacobian(fx, x)
        fxθ = Symbolics.jacobian(fx, θ)

        f_expr = Symbolics.build_function(f, x, θ,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fx_expr = Symbolics.build_function(fx, x, θ,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fθ_expr = Symbolics.build_function(fθ, x, θ,
            parallel=((threads && num_parameters > 0) ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fxx_expr = Symbolics.build_function(fxx, x, θ,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fxθ_expr = Symbolics.build_function(fxθ, x, θ,
            parallel=((threads && num_parameters > 0) ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]

        return f_expr, fx_expr, fθ_expr, fxx_expr, fxθ_expr
    elseif mode == :vector 
        f = func(x, θ)
        
        fx = Symbolics.jacobian(f, x)
        fθ = Symbolics.jacobian(f, θ)

        @variables y[1:length(f)]
        # y = Symbolics.variables(:y, 1:length(f))

        fᵀy = length(f) == 0 ? 0.0 : sum(transpose(f) * y)
        fᵀyx = Symbolics.gradient(fᵀy, x)
        fᵀyxx = Symbolics.jacobian(fᵀyx, x) 
        fᵀyxθ = Symbolics.jacobian(fᵀyx, θ) 

        f_expr = Symbolics.build_function(f, x, θ,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fx_expr = Symbolics.build_function(fx, x, θ,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fθ_expr = Symbolics.build_function(fθ, x, θ,
            parallel=((threads && num_parameters > 0) ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fᵀy_expr = Symbolics.build_function([fᵀy], x, θ, y,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fᵀyx_expr = Symbolics.build_function(fᵀyx, x, θ, y,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fᵀyxx_expr = Symbolics.build_function(fᵀyxx, x, θ, y,
            parallel=(threads ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]
        fᵀyxθ_expr = Symbolics.build_function(fᵀyxθ, x, θ, y,
            parallel=((threads && num_parameters > 0) ? Symbolics.MultithreadedForm() : Symbolics.SerialForm()),
            checkbounds=checkbounds, 
            expression=Val{false})[2]

        return f_expr, fx_expr, fθ_expr, fᵀy_expr, fᵀyx_expr, fᵀyxx_expr, fᵀyxθ_expr
    end
end

empty_constraint(x, θ) = zeros(0) 