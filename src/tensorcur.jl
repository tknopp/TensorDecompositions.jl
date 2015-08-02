type CUR
    Cindex::Array{Int64, 1}
    Cweight::Array{Int64, 1}
    Rindex::Array{(Int64, Int64), 1}
    Rweight::Array{Int64, 1}
    U::Array{Float64, 2}
    residual::Float64

    function CUR(T::StridedArray,
                 Cindex::Array{Int64, 1},
                 Rindex::Array{Int64, 1},
                 Cweight::Array{Int64, 1},
                 Rweight::Array{Int64, 1},
                 U::Array{Float64, 2},
                 compute_u::Bool)

        res = NaN 
        if compute_u
            S = tensorcontract(T[Cindex, :, :], [1, 2, 3], U, [4, 1], [4, 2, 3])
            S = tensorcontract(T[:, Rindex], [1, 2], S, [2, 3, 4], [1, 3, 4])
            res = vecnorm(S - T)
        end
        new(Cindex, Cweight, 
            [(i%size(T, 2) + 1, div(i, size(T, 3)) + 1)::(Int64, Int64) for i = Rindex], 
            Rweight, U, res) 

    end

end

function tensorcur3(T::StridedArray, 
                    c::Integer, r::Integer, 
                    slab_axis::Integer=3; 
                    compute_u::Bool=true)

    @assert ndims(T) == 3
    @assert slab_axis in {1,2,3}
    T = permutedims(T, [slab_axis, 1:slab_axis-1, slab_axis+1:3])
    T2 = T .^ 2
    T2_sum = sum(T2)
    p = sum(T2, [2, 3])[:] / T2_sum
    q = sum(T2, 1)[:] / T2_sum

    Cindex = rand(Categorical(p), c)
    Rindex = rand(Categorical(q), r)
    Cweight = hist(Cindex, 0:size(T, 1))[2]  
    Rweight = hist(Rindex, 0:size(T, 2)*size(T, 3))[2]
    Cindex = sort(unique(Cindex))
    Rindex = sort(unique(Rindex))
    Cweight = Cweight[Cindex]
    Rweight = Rweight[Rindex]
 
    U = compute_u ? Array(Float64, r, c) : zeros(0, 0) 
    if compute_u
        p = Cweight ./ p[Cindex]
        q = Rweight ./ q[Rindex]
        U = pinv(T[Cindex, :, :][:, Rindex] .* p .* q') .* p' .* q
    end

    return CUR(T, Cindex, Rindex, Cweight, Rweight, U, compute_u)
end
