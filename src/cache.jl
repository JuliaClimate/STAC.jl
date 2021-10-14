


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
    STACatalogs.set_cache_max_size(cache_max_size::Integer)

Set the maximum number of URLs saved in cache (permanentaly). The default is 1000.
The Julia session need to be restated for this change to take effect.
"""
function set_cache_max_size(cache_max_size::Integer)
    @set_preferences!("cache_max_size" => cache_max_size)
    @info("New cache maximum size set; restart your Julia session for this change to take effect")
end
