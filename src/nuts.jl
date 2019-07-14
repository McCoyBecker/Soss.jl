using TransformVariables, LogDensityProblems, DynamicHMC, MCMCDiagnostics, Parameters,
    Distributions, Statistics, StatsFuns, ForwardDiff

struct NUTS_result{T}
    chain::Vector{NUTS_Transition{Vector{Float64},Float64}}
    transformation
    samples::Vector{T}
    tuning
end

Base.show(io::IO, n::NUTS_result) = begin
    println(io, "NUTS_result with samples:")
    println(IOContext(io, :limit => true, :compact => true), n.samples)
end

export nuts


function nuts(m :: Model; kwargs...)
    result = NUTS_result{}
    t = xform(m; kwargs...)
    fpre = @eval $(sourceLogdensity(m))
    # fpre = @logdensity m
    f(pars) = Base.invokelatest(fpre, merge(kwargs, pairs(pars)))
    # f(pars) = invoke(fpre, merge(kwargs, pairs(pars)))
    P = TransformedLogDensity(t, f)
    ∇P = ADgradient(:ForwardDiff, P)
    chain, tuning = NUTS_init_tune_mcmc(∇P, 1000);
    samples = TransformVariables.transform.(Ref(parent(∇P).transformation), get_position.(chain));
    NUTS_result(chain, t, samples, tuning)
end
