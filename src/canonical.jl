using MLStyle

export canonical
using Lazy
canonical(x) = x

function canonical(expr :: Expr)
    # @show expr
    r = canonical
    @match expr begin
        :($x |> $f) => begin
            rf = r(f)
            rx = r(x)
            :($rf($rx)) |> r
        end

        Expr(:do, :($g($x)), :($f)) => begin
            rg = r(g)
            rf = r(f)
            rx = r(x)            
            :($rg($rf, $rx)) |> r
        end        
        
        :((iid($n))($dist)) => begin
            rn = r(n)
            rdist = r(dist)
            :(iid($rn,$rdist)) |> r
        end

        :($f($(args...))) => begin
            rf = r(f)
            rx = map(r,args)
            :($rf($(rx...)))
        end

        :(iid($n)($dist)) => begin
            rn = r(n)
            rdist = r(dist)
            :(iid($rn,$rdist)) |> r
        end

        # TODO: This was intended to work around the closure issues by rewriting it as a local fucntion with all values passed explicitly as arguments. Doesn't seem to work, at least not yet
        :($x -> begin $lnn; $fbody end) => begin
            vs = setdiff(variables(fbody), variables(x))
            @gensym f
            pars = astuple(variables(x))
            pars = :($(Expr(:parameters)))
            for v in vs
                pushfirst!(pars.args, :($v=$v))
            end
            quote
                $f($pars) = $fbody
                $f
            end
        end |> r

        x => x
    end
end

function canonical(m :: Model)
    @as x m begin
        convert.(Expr, x.body)
        canonical.(x)
        convert.(Statement, x)
        Model(m.args, x)
    end
end    

ex1 = :(map(1:10) do x x^2 end)

# canonical(ex1)
# canonical(linReg1D)