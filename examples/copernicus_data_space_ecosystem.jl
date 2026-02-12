# Copernicus Data Space Ecosystem STAC Catalog

# Download sentinel-2-l1c data using STAC.jl from the Copernicus Data
# Space Ecosystem STAC

using STAC
using Dates
using HTTP
using JSON3

collections = ["sentinel-2-l1c"]
time_range = (DateTime(2026,2,9,10,20), DateTime(2026,2,9,10,30))
lon_range = (0, 20)  # west, east
lat_range = (32, 45)  # south, north

catalog = STAC.Catalog("https://stac.dataspace.copernicus.eu/v1/")

search_results = collect(search(catalog, collections, lon_range, lat_range, time_range))

@info "$(length(search_results)) item(s) found"

item = search_results[1]

# inspect the first item

display(item)

# Register at https://dataspace.copernicus.eu/
# and replace here your username and password, e.g.
#
# CDSE_USERNAME = "my.email@address.be"
# CDSE_PASSWORD = "secret" (escape special characters if needed)
#
# or define the environnement variables CDSE_USERNAME and CDSE_PASSWORD
# otherwise you will get the error: key "CDSE_USERNAME" not found

CDSE_USERNAME = ENV["CDSE_USERNAME"]
CDSE_PASSWORD = ENV["CDSE_PASSWORD"]

# Get a token following the API documentation:
# https://documentation.dataspace.copernicus.eu/APIs/Token.html
function cdse_token(username, password;
                    auth_url = "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token",
                    client_id = "cdse-public"
                    )

    data = Dict(
        "client_id" => client_id,
        "grant_type" => "password",
        "username" => username,
        "password" => password,
    )

    r = HTTP.post(auth_url,[],data)
    resp = JSON3.read(r.body)
    return resp["access_token"]
end

function download(url,filename,token)
    headers = ["Authorization" => "Bearer $token"]
    HTTP.open("GET", url, headers) do stream
        open(filename, "w") do file
            while !eof(stream)
                write(file, readavailable(stream))
            end
        end
    end
    return nothing
end


token = cdse_token(CDSE_USERNAME,CDSE_PASSWORD)

# get URL of data product
url = href(item.assets["Product"])

# local filename is based on the product id followed by the .zip file extention
filename = string(id(item),".zip")

# download example file (264M)
@info "downloading $filename"
download(url,filename,token)
