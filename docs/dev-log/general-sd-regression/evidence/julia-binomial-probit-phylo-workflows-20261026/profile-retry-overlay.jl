# Test-only overlay for the probit phylogenetic SD profile diagnostic.
# This file is loaded into a JuliaCall session after `using DRModels` and
# before the focused bridge test. It does not modify the candidate source.

using DRModels

@eval DRModels begin
    function _profile_attempt(
        obj,
        u0,
        method::Symbol,
        autodiff::Symbol;
        (grad!)=nothing,
        iterations::Union{Nothing,Int}=nothing,
        fallback::Bool=false,
    )
        res = try
            if method === :lbfgs_stored
                od = Optim.OnceDifferentiable(obj, grad!, u0)
                ls = Optim.LineSearches.BackTracking(; iterations=20)
                Optim.optimize(
                    od, u0, Optim.LBFGS(; linesearch=ls),
                    Optim.Options(; iterations=something(iterations, 40), g_tol=1e-6, x_abstol=1e-8),
                )
            elseif method === :nelder_mead
                iterations === nothing ? Optim.optimize(obj, u0, Optim.NelderMead()) :
                    Optim.optimize(
                        obj, u0, Optim.NelderMead(), Optim.Options(; iterations, x_abstol=1e-8),
                    )
            elseif method === :lbfgs_finite_backtracking
                ls = Optim.LineSearches.BackTracking(; iterations=20)
                iterations === nothing ?
                    Optim.optimize(
                        obj, u0, Optim.LBFGS(; linesearch=ls); autodiff,
                    ) :
                    Optim.optimize(
                        obj, u0, Optim.LBFGS(; linesearch=ls),
                        Optim.Options(; iterations, g_tol=1e-6, x_abstol=1e-8);
                        autodiff,
                    )
            else
                iterations === nothing ?
                    Optim.optimize(obj, u0, Optim.LBFGS(); autodiff) :
                    Optim.optimize(
                        obj, u0, Optim.LBFGS(),
                        Optim.Options(; iterations, g_tol=1e-6, x_abstol=1e-8);
                        autodiff,
                    )
            end
        catch err
            err isa InterruptException && rethrow()
            @warn "test-only profile optimizer attempt exception" method fallback error=sprint(showerror, err)
            return (value=NaN, minimizer=Float64[], accepted=false, method=method,
                    fallback=fallback, reason=:exception)
        end
        minimizer = try
            Float64.(Optim.minimizer(res))
        catch err
            err isa InterruptException && rethrow()
            Float64[]
        end
        all(isfinite, minimizer) || return (
            value=NaN, minimizer=minimizer, accepted=false, method=method,
            fallback=fallback, reason=:nonfinite_minimizer,
        )
        value = try
            Float64(obj(minimizer))
        catch err
            err isa InterruptException && rethrow()
            NaN
        end
        isfinite(value) || return (
            value=value, minimizer=minimizer, accepted=false, method=method,
            fallback=fallback, reason=:nonfinite_objective,
        )
        Optim.converged(res) || return (
            value=value, minimizer=minimizer, accepted=false, method=method,
            fallback=fallback, reason=fallback ? :fallback_not_converged : :not_converged,
        )
        return (value=value, minimizer=minimizer, accepted=true, method=method,
                fallback=fallback, reason=:accepted)
    end
end

@eval DRModels begin
    function _profile_optimize_result(
        obj,
        u0::Vector{Float64},
        autodiff::Symbol;
        (grad!)=nothing,
        primary_iterations::Union{Nothing,Int}=nothing,
        fallback_iterations::Union{Nothing,Int}=nothing,
        primary_attempt=nothing,
    )
        primary_method = grad! === nothing ?
            (autodiff === :finite ? :lbfgs_finite : :lbfgs_forward) : :lbfgs_stored
        primary = primary_attempt === nothing ?
            _profile_attempt(obj, u0, primary_method, autodiff;
                             (grad!)=grad!, iterations=primary_iterations) :
            primary_attempt(obj, u0, primary_method, autodiff, grad!)
        primary.accepted && return primary

        if grad! === nothing && autodiff === :finite &&
           primary.reason === :not_converged && isfinite(primary.value) &&
           all(isfinite, primary.minimizer)
            return _profile_attempt(
                obj, primary.minimizer, :lbfgs_finite_backtracking, :finite;
                iterations=something(primary_iterations, 3000), fallback=true,
            )
        end

        if grad! !== nothing && primary.reason === :not_converged &&
           isfinite(primary.value) && all(isfinite, primary.minimizer)
            continuation = _profile_attempt(
                obj, primary.minimizer, :lbfgs_stored, autodiff;
                (grad!)=grad!, iterations=something(primary_iterations, 40),
                fallback=true,
            )
            continuation.accepted && return continuation
            return continuation
        end

        if grad! !== nothing && primary.reason === :exception
            return _profile_attempt(
                obj, u0, :lbfgs_finite, :finite;
                iterations=something(primary_iterations, 40), fallback=true,
            )
        elseif grad! === nothing && autodiff === :finite &&
               primary.reason === :exception
            return _profile_attempt(
                obj, u0, :nelder_mead, :finite;
                iterations=fallback_iterations, fallback=true,
            )
        end
        return primary
    end
end
