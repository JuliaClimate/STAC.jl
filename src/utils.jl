mutable struct LazyOrderedDict{K,V} <: AbstractDict{K,V}
    fun
    list
    data::Union{Nothing,OrderedDict{K,V}}
end

#LazyOrderedDict(load!) = LazyOrderedDict(load!,nothing)

Base.length(ld::LazyOrderedDict) = length(ld.list)


function load!(ld::LazyOrderedDict)
    if ld.data == nothing
        ld.data = OrderedDict(ld.fun.(ld.list)...)
    end
end

function Base.keys(ld::LazyOrderedDict)
    load!(ld)
    return collect(keys(ld.data))
end

function Base.getindex(ld::LazyOrderedDict{K,V},id::K) where {K,V}
    load!(ld)
    return ld.data[id]
end

#=
function Base.iterate(ld::LazyOrderedDict, state = keys(ld))
    if length(state) == 0
        return nothing
    end

    return (state[1] => ld[popfirst!(state)], state)
end
=#
function Base.iterate(ld::LazyOrderedDict, state = copy(ld.list))
    if length(state) == 0
        return nothing
    end

    return (ld.fun(popfirst!(state)), state)
end
