
struct Item
    url::String
    data
    assets
end

for prop in [:bbox]
    @eval $prop(item::Item) = item.data[$prop]
    @eval export $prop
end

function Item(url)
    data = cached_resolve(url)
    assets = data[:assets]
    return Item(url,data,assets)
end
