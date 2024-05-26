## This does TCN neural net estimation for the DSGE example
using PrettyTables, Pkg, DelimitedFiles, Distributions, LinearAlgebra, MCMCChains, StatsPlots
cd(@__DIR__)
Pkg.activate(".")
# defines the net and the DSGE model, and needed functions
include("Setup.jl")

## Monte Carlo to see how the raw TCN estimator performs
reps = 100
net = load_trained()
Flux.testmode!(net)
θtrue = TrueParameters()
@time data = MakeData(θtrue, reps, CKmodel)
@time θnn = Float64.(UntransformParameters(net(data)))
m = mean(θnn, dims=2)
e = θnn .- TrueParameters()
s = std(e, dims=2)
b = mean(e, dims=2)
r = sqrt.(mean(e.^2, dims=2))
printstyled("Monte Carlo TCN neural net results for the DSGE model, $(reps) replications\n", color=:green)
pretty_table(round.([TrueParameters() m b s r],digits=4), header=["True", "mean", "bias", "st. dev.", "rmse"])


## Now, let's move on to Bayesian MSM using the typical data set
# load the data
data = readdlm("dsgedata.txt")
# transform the data the same way as was used to train net
data .-= [0.84, 0.69, 0.33, 0.05, 1.72]'
data ./= [0.51, 0.44, 0.36, 0.018, 0.34]'
X = zeros(Float32, 160, 1, 5)
X[:, 1, :] = Float32.(data)

## This is the raw TCN estimate using the official data set
θnn = Float64.(UntransformParameters(net(tabular2conv(permutedims(Float32.(X), (3, 2, 1))))))[:]

#################### Define functions for MCMC ###############################

# compute mean and cov of moments, for obj fn and proposal
function simmomentscov(θ::Vector{Float64}, S::Int64)
m = Float64.(UntransformParameters(net(MakeData(θ, S, CKmodel)))')
mean(m, dims=1)[:], cov(m)
end

# CUE objective, written to MAXIMIZE
@inbounds function bmsmobjective(θ::Vector{Float64}, θnn::Vector{Float64}, S::Int64)  
    # Make sure the trial parameter value is in the support
    InSupport(θ) || return -Inf
    # Compute simulated moments and covariance
    θbar, Σ = simmomentscov(θ, S)
    n = 160 # sample size
    Σ *= n * (1+1/S) # 1 for θhat, 1/S for θbar
    isposdef(Σ) || return -Inf
    err = sqrt(n)*(θnn-θbar) 
    W = inv(Σ)
    -0.5*dot(err, W, err)
end

# proposal: MVN random walk
@inbounds function proposal(current::Vector{Float64}, δ::Float64, Σ::Array{Float64})
    rand(MvNormal(current, δ*Σ))
end

@views function mcmc(
    θ::Vector{Float64}; # TODO: prior? not needed at present, as priors are uniform
    Lₙ::Function, proposal::Function, burnin::Int=100, N::Int=1_000,
    verbosity::Int=10
)
    Lₙθ = Lₙ(θ) # Objective at data moments value
    naccept = 0 # Number of acceptance / rejections
    accept = false
    acceptance_rate = 1f0
    chain = zeros(N, size(θ, 1) + 2)
    for i ∈ 1:burnin+N
        θᵗ = proposal(θ) # new trial value
        Lₙθᵗ = Lₙ(θᵗ) # Objective at trial value
        # Accept / reject trial value
        accept = rand() < exp(Lₙθᵗ - Lₙθ)
        if accept
            # Replace values
            θ = θᵗ
            Lₙθ = Lₙθᵗ
            # Increment number of accepted values
            naccept += 1
        end
        # Add to chain if burnin is passed
        # @info "current log-L" Lₙθ
        if i > burnin
            chain[i-burnin,:] = vcat(θ, accept, Lₙθ)
        end
        # Report
        if verbosity > 0 && mod(i, verbosity) == 0
            acceptance_rate = naccept / verbosity
            @info "Current parameters (iteration i=$i)" round.(θ, digits=3)' acceptance_rate
            naccept = 0
        end
    end
    return chain
end

#################### End Define functions for MCMC ###############################


## set up proposal and chain

# proposal
covreps = 1000
_,Σₚ = simmomentscov(θnn, covreps)
δ = 0.75 # tuning

# define objective and proposal
S = 50  # number of simulations for moments
obj = θ -> bmsmobjective(θ, θnn, S)
prop = θ -> proposal(θ, δ, Σₚ)

## run the chain
chain = mcmc(θnn, Lₙ=obj, proposal=prop, N=500)
# report results
chn = Chains(chain[:,1:end-2], ["β", "γ", "ρ₁", "σ₁", "ρ₂", "σ₂", "nss"])
plot(chn)
savefig("chain.png")
display(chn)
pretty_table([TrueParameters() θnn mean(chain[:,1:end-2],dims=1)[:]], header = (["θtrue", "θnn", "θmcmc"]))
