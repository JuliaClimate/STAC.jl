abstract type AbstractConformanceClass
end

struct STACConformanceClass <: AbstractConformanceClass
    version::VersionNumber
    class::String
    fragment::String
end


STACConformanceClass(version::VersionNumber,class) =
    STACConformanceClass(version,class,"")


function compatible(needs::VersionNumber,has::VersionNumber)
    if needs.major == has.major
        if needs.major == 0
            return needs.minor = has.minor
        end
        return true
    end
    return false
end

function match(class::STACConformanceClass,c::AbstractString)
    u = URI(c)
    if u.host != "api.stacspec.org"
        return false
    end

    if u.fragment != class.fragment
        return false
    end

    _,v,c = split(u.path,'/')

    if c != class.class
        return false
    end

    return compatible(class.version,VersionNumber(v))
end

function conforms(conforms_to::AbstractVector{<:AbstractString},class::AbstractConformanceClass)
    for c in conforms_to
        if match(class,c)
            return true
        end
    end
    return false

end

function conforms(catalog::STAC.Catalog,class::AbstractConformanceClass)
    return conforms(catalog.data.conformsTo,class)
end

const CONFORMANCE = (
    core = STACConformanceClass(v"1","core"),
    collections = STACConformanceClass(v"1","collections"),
    item_search = STACConformanceClass(v"1","item-search"),
    context = STACConformanceClass(v"1","item-search","context"),
    fields = STACConformanceClass(v"1","item-search","fields"),
    sort = STACConformanceClass(v"1","item-search","sort"),
    query = STACConformanceClass(v"1","item-search","query"),
    filter = STACConformanceClass(v"1","item-search","filter"),
)
