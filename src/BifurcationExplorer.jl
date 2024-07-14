module BifurcationExplorer

using BifurcationKit
using BifurcationKit: detect_bifurcation

using Bonito

using WGLMakie: pick
using WGLMakie

# define system
F(x, p) = @. p.μ + x - x^3 / 3
opts = ContinuationPar(p_min=-1.0, p_max=1.0)
problem = Observable(BifurcationProblem(F, [-2.0], (μ=-1.0,), (@lens _.μ)))

branch = Observable{Vector{Point{2,Float64}}}([])
bifurcations = Observable{Vector{Point{2,Float64}}}([])

# run continuation every time the problem changes
on(problem) do problem
    iter = ContIterable(problem, PALC(), opts; verbosity=0)
    for state in iter
        point = (state.z.p, state.z.u[1])

        push!(branch[], point)
        notify(branch)

        if detect_bifurcation(state)

            push!(bifurcations[], point)
            notify(bifurcations)

            @info "Bifurcation detected at $(point)"
            break
        end
        sleep(0.1)
    end
end

app = App() do session::Session

    # main app layout
    figure = Figure(size=(512, 512))
    ax = Axis(figure[1, 1],
        xlabel=L"Parameter, $p$",
        ylabel=L"Fixed points, $F(\mathrm{\mathbf{u}}, p)=0$",
        title="Bifurcation Diagram",
        limits=(opts.p_min, opts.p_max, -3, 3),)

    lines_plot = lines!(ax, branch, color=:blue)
    scatter_plot = scatter!(ax, bifurcations, color=:orange, markersize=12)

    # onclick bifurcation point event handler
    on(events(figure).mousebutton, priority=2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            picked_plot, i = pick(figure)

            if picked_plot == scatter_plot
                p, u = bifurcations[][i]

                problem[] = re_make(problem[]; u0=[u], params=(μ=p,))
                return Consume(true)
            end

        end
        return Consume(false)
    end

    return figure
end

notify(problem)
end