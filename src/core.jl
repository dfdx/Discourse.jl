
using Requests
using URIParser
using JSON


struct Discourse
    base_url::String
    api_key::String
    api_username::String
end


function Discourse(;base_url="https://discourse.julialang.org",
                   api_key=ENV["DISCOURSE_API_KEY"],
                   api_username=ENV["DISCOURSE_API_USERNAME"])
    return Discourse(base_url, api_key, api_username)    
end


function Base.show(io::IO, ds::Discourse)
    uri = URI(ds.base_url)
    print(io, "Discourse(host=$(uri.host), user=$(ds.api_username))")
end

## http wrappers

function do_get(ds::Discourse, endpoint::String; query...)
    query = Dict{Any,Any}(query)
    query[:api_key] = ds.api_key
    query[:api_username] = ds.api_username
    resp = get(ds.base_url * endpoint; query=query)
    if resp.status == 200
        return JSON.parse(String(resp.data))
    else
        error("Discourse API returned an error: status=$(resp.status); data=$(String(resp.data))")
    end
end


function do_post(ds::Discourse, endpoint::String, json::Dict)
    query = Dict{Any,Any}()
    query[:api_key] = ds.api_key
    query[:api_username] = ds.api_username
    resp = post(ds.base_url * endpoint; json=json, query=query)
    if resp.status == 200
        return JSON.parse(String(resp.data))
    else
        error("Discourse API returned an error: status=$(resp.status); data=$(String(resp.data))")
    end
end


## methods

# users

function list_public_users(ds::Discourse; query...)
    return do_get(ds, "/directory_items.json"; query)
end



# topics & posts


function get_topic(ds::Discourse, id::Integer)
    return do_get(ds, "/t/$id.json")
end


function get_post(ds::Discourse, id::Integer)
    return do_get(ds, "/posts/$id.json")
end



function create_post(ds::Discourse, topic_id::Int, content::AbstractString)
    data = Dict(:topic_id => topic_id,
                :raw => content)
    return do_post(ds, "/posts", data)
end


function create_topic(ds::Discourse, title::Int, content::AbstractString;
                      category=nothing, created_at=nothing)
    data = Dict(:title => title,
                :raw => content)
    if category != nothing
        data[:category] = category
    end
    if created_at != nothing
        data[:created_at] = created_at
    end
    return do_post(ds, "/posts", data)
end



