# initialize
function initialize_nonnegative!(x, idx_ineq; 
    initial=1.0) 
    for i in idx_ineq
        x[i] = initial
    end
    return 
end

# barrier 
nonnegative_barrier(x) = sum(log.(x)) 
nonnegative_barrier_gradient(x) = 1.0 ./ x

# product 
nonnegative_product(a, b) = a .* b 

function nonnegative_product_jacobian(a, b) 
    Diagonal(b) 
end

# target 
nonnegative_target(x) = ones(length(x))

# violation 
function nonnegative_violation(x)
    for xi in x 
        xi <= 0.0 && (return true)
    end 
    return false 
end
