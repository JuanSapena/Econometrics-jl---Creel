#  Negative Binomial type 1 and type II log likelihood
#  The parameterization follows
#  Deb and Trivedi, J. Appl. Econometrics,
#  V. 12, 1997, pp. 313 - 336.
using SpecialFunctions
function  negbin(θ, y, x, nbtype)
    n, k = size(x)
    β = θ[1:k]
    λ = exp.(x*β)
    α = exp(θ[end])
    nbtype == 1 ? ψ = λ/α : ψ = ones(n)/α
    logdensity = loggamma.(y .+ ψ) - loggamma.(ψ) - loggamma.(y .+ 1.0)
                + ψ .* log.(ψ ./ (λ + ψ)) + y .* log.(λ ./(λ + ψ)) 
end

