


const CACHE = LRU(maxsize = @load_preference("cache_max_size", 1000))

resolve(url) = JSON3.read(String(HTTP.get(url).body))

function cached_resolve(url)
    @debug "url $url in cache: $(haskey(CACHE,url))"

    get!(CACHE, url) do
        @debug "get $url", typeof(url)
        resolve(url)
    end
end

"""
    STAC.set_cache_max_size(cache_max_size::Integer)

Set the maximum number of URLs saved in cache (permanentaly). The default is 1000.
"""
function set_cache_max_size(cache_max_size::Integer)
    @set_preferences!("cache_max_size" => cache_max_size)
    resize!(CACHE; maxsize = cache_max_size)
end


"""
    STAC.empty_cache()

Empty the URL cache.
"""
empty_cache() = empty!(CACHE)
