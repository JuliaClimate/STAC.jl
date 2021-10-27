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

Set the $($item_str) color. The default color is `Base.$($default_str)()`.
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
