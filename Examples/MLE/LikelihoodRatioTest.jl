# example showing how to do maximum likelihood estimation
# for data generated by CLRM with normality
# sample size

##
using Econometrics, Distributions
n = 1000
# random true parameters
theta = [1.0,-1.0,0.0,1.0]
b = theta[1:3]
sig = theta[4]
# generate random data
x = [ones(n,1) rand(n,2)]
e = sig*randn(n,1)
y = x*b + e

## do ML
obj = theta -> -mean(normal(theta, y, x))
thetahat, logL, junk = fminunc(obj, theta)
logL = -logL

## restricted ML
R = [0 1 0 0]
r = -1.5
thetahatr, logLr, junk = fmincon(obj, theta, R, r)
logLr = -logLr

## LR rest
LR = 2.0*n*(logL-logLr)

## results
println("the true parameters: ", theta)
println("the ML estimates: ", thetahat)
println("the restricted ML estimates: ", thetahatr)
println("the LR test: ", LR);
println("p-value of the LR test: ", 1.0-cdf(Chisq(1),LR))
