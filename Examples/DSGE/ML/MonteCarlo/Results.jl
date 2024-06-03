using Statistics, DelimitedFiles, PrettyTables
cd(@__DIR__)
# get the things to define the structure for the model
include("CKlib.jl") # contains the functions for the DSGE model

posmodes = readdlm("posmodes")
θtrue = TrueParameters()
errs = posmodes .- θtrue'
b = mean(errs, dims=1)[:]
m = b .+ θtrue
s = std(errs, dims=1)[:]
r = sqrt.(b.^2 + s.^2)[:]
names = ["β", "γ", "ρ₁", "σ₁", "ρ₂", "σ₂", "nss"] 
printstyled("Monte Carlo ML (linearized model, using c and n), 1000 reps\n", color=:green)
pretty_table([names round.([TrueParameters() m b s r],digits=4)],
 header=["parameter", "true", "mean", "bias", "st. dev.", "rmse"])

