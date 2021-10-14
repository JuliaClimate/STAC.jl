
const lru = LRU(maxsize = 1000)
#const lru = Dict()

resolve(url) = JSON3.read(String(HTTP.get(url).body))

function cached_resolve(url)
    @debug "url $url in cache: $(haskey(lru,url))"

    get!(lru, url) do
        @debug "get $url", typeof(url)
        resolve(url)
    end
end


