struct Link{TMIME,TTitle,Tbody}
    href::String
    rel::Symbol
    type::TMIME
    title::TTitle
    method::Symbol #  HTTP method, :get by default
    headers::Dict{String,String}
    body::Tbody
end

function Link(data::AbstractDict{Symbol})
    # check headers
    Link(data[:href],
         Symbol(data[:rel]),
         (haskey(data,:type) ? MIME(data[:type]) : nothing),
         get(data,:title,nothing),
         get(data,:method,:get),
         get(data,:headers,Dict{String,String}()),
         get(data,:body,nothing),
         )
end


function firstlink(entry; rel = nothing, type = nothing)
    for l in links(entry)
        if isnothing(rel) || rel == l.rel
            if isnothing(type) || type == l.type
                return l
            end
        end
    end
end
