mutable struct LazyOrderedDict{K,V} <: AbstractDict{K,V}
    # function to generate (key => value) for every element in list
    fun
    getindex_guess
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
    if ld.getindex_guess !== nothing
        guess = ld.getindex_guess(ld.list,ld.fun,id)
        if guess !== nothing
            return guess
        end
    end
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


struct OrderedDictWrapper{Tdata,Tgetindex,Tkeys} <: AbstractDict{String,Any}
    data::Tdata
    keys::Tkeys
    getindex::Tgetindex
    make_channel
end

Base.keys(odw::OrderedDictWrapper) = odw.keys(odw.data)
Base.getindex(odw::OrderedDictWrapper,key) = odw.getindex(odw.data,key)
function Base.getindex(odw::OrderedDictWrapper, intkey::Integer)
    odwkeys = keys(odw)
    outkey = eltype(odwkeys)[]
    for (i, key) in enumerate(odwkeys)
        if i == intkey
            push!(outkey, key)
            break
        end
    end
    if isempty(outkey)
        throw(BoundsError(odw, intkey))
    end
    odw.getindex(odw.data, outkey[1])
end

function Base.show(io::IO, m::MIME"text/plain", odw::OrderedDictWrapper)
    _printstyled(io, typeof(odw),"\n")
    _printstyled(io, odwtype(odw.getindex))
    _printstyled(io, "Parent Catalog: ", title(odw.data))
end

Base.show(io::IO, odw::OrderedDictWrapper) = show(io, MIME("text/plain"), odw) 
odwtype(x) = string(x) * " of "
Base.length(odw::OrderedDictWrapper) = length(collect(keys(odw)))

# https://github.com/JuliaLang/julia/blob/95c643a689293eb91a47cc83c41533a94c3677cc/base/channels.jl
function Base.iterate(odw::OrderedDictWrapper, channel = odw.make_channel(odw.data))
    if isopen(channel) || isready(channel)
        try
            element = take!(channel)
            return (id(element) => element,channel)
        catch e
            if isa(e, InvalidStateException) && e.state === :closed
                return nothing
            else
                rethrow()
            end
        end
    else
        return nothing
    end
end

function Base.get(odw::OrderedDictWrapper, name::String, default)
    if haskey(odw,name)
        return odw[name]
    else
        return default
    end
end


for (item_color,default) in (
    (:title_color, :error_color),
    (:catalog_color, :info_color),
    (:item_color, :info_color),
    (:asset_color, :info_color),
)

    item_color_str = String(item_color)
    item_str = split(item_color_str,"_")[1]
    default_str = String(default)

    @eval begin
        $item_color = Ref(Symbol(load_preference(STAC,$(item_color_str), Base.$default())))

        """
        STAC.set_$($item_color_str)(color::Symbol)

Set the $($item_str) color. The default color is `Base.$($default_str)()`. The
color is saved using [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl).
"""
        function $(Symbol(:set_,item_color))(color::Symbol)
            @set_preferences!($(item_color_str) => String(color))
            $item_color[] = color
        end

    end
end

# print unless one argument is nothing
function _print(args...; kwargs...)
    if !any(isnothing,args)
        print(args...; kwargs...)
    end
end

function _printstyled(args...; kwargs...)
    if !any(isnothing,args)
        printstyled(args...; kwargs...)
    end
end

_assets(data) = OrderedDict((String(k) => Asset(v) for (k,v) in get(data,:assets,[])))

function _show_assets(io,item)
    ident = "  "

    if length(item.assets) > 0
        println(io,"Assets:")
        for (id,asset) in item.assets
            print(io,ident," * ")
            printstyled(io, id, color=asset_color[])

            _print(io,": ",title(asset),"")
            printstyled(io, "\n")
        end
    end

end
