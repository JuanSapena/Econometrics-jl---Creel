function ridge(y, x, k)
    # standardize regressors (except the constant)
    s = std(x,dims=1)
    for i = 1:size(x,2)
        if s[i]==0
            s[i] = 1.0
        end
    end    
    x = x ./ s
    A = eye(size(x,2))
    A[1,1] = 0.0
    βhat = (inv(x'x + k*eye(size(x,2)))*x'y) ./ s'
end


# shrink towards a target vector which may not be zeros
function ridge(y, x, k, target)
    # standardize regressors (except the constant)
    s = std(x,dims=1)
    for i = 1:size(x,2)
        if s[i]==0
            s[i] = 1.0
        end
    end    
    x = x ./ s
    A = eye(size(x,2))
    A[1,1] = 0.0
    β = (inv(x'x + k*eye(size(x,2)))*[x'y + k.*target]) ./ s'
end