using HTTP, JSON, Sockets

# Load SDK path (for reference)
directory = raw"C:\Users\KYZMA\Downloads\imessage-kit-main"
sdk_path = joinpath(directory, "imessage-kit-main", "src", "core", "sdk.ts")

# Intent recognition keywords
const SEARCH_KEYWORDS = ["find", "search", "looking for", "want", "need", "show", "suggest", "recommend", "pick"]
const RESTAURANT_KEYWORDS = ["restaurant", "food", "hungry", "eating", "dine", "dinner", "lunch", "breakfast", "cuisine", "place", "eat"]

function detect_restaurant_intent(user_input::String)::Tuple{Bool, String}
    lower_input = lowercase(user_input)
    has_search = any(keyword in lower_input for keyword in SEARCH_KEYWORDS)
    has_restaurant = any(keyword in lower_input for keyword in RESTAURANT_KEYWORDS)
    if has_search && has_restaurant
        return (true, user_input)
    elseif has_restaurant
        return (true, user_input)
    else
        return (false, "")
    end
end

function extract_search_parameters(user_input::String)::String
    cuisine_keywords = ["italian", "chinese", "japanese", "mexican", "thai", "french", "japanese", "indian", "pizza", "burger", "sushi", "taco"]
    lower_input = lowercase(user_input)
    for cuisine in cuisine_keywords
        if cuisine in lower_input
            return cuisine
        end
    end
    return user_input
end

function process_restaurant_request(user_prompt::String)::Dict{String, Any}
    is_restaurant_search, _ = detect_restaurant_intent(user_prompt)
    if !is_restaurant_search
        return Dict("error" => "Not a restaurant search request", "status" => "rejected")
    end

    search_query = extract_search_parameters(user_prompt)

    try
        url = "https://opentable.com/api/restaurants?query=$(HTTP.escapeuri(search_query))"
        response = HTTP.get(url)
        data = JSON.parse(String(response.body))

        if haskey(data, "restaurants") && !isempty(data["restaurants"])
            restaurant = data["restaurants"][1]
            return Dict(
                "status" => "success",
                "restaurant" => Dict(
                    "name" => get(restaurant, "name", "Unknown"),
                    "cuisine" => get(restaurant, "cuisine", "N/A"),
                    "location" => get(restaurant, "location", "N/A"),
                    "rating" => get(restaurant, "rating", "N/A")
                )
            )
        else
            return Dict("status" => "no_results", "message" => "No restaurants found for: $search_query")
        end
    catch e
        return Dict("status" => "error", "message" => "API error: $e")
    end
end

# HTTP Server for iMessage SDK integration
function start_server()
    println("🍽️ Restaurant Picker Server starting on port 8080...")
    println("Ready for iMessage SDK integration")

    HTTP.serve("0.0.0.0", 8080) do request::HTTP.Request
        try
            if request.method == "POST" && occursin("/restaurant", request.target)
                # Parse JSON body
                body = JSON.parse(String(request.body))
                user_prompt = get(body, "prompt", "")

                if isempty(user_prompt)
                    return HTTP.Response(400, JSON.json(Dict("error" => "Missing prompt")))
                end

                # Process request
                result = process_restaurant_request(user_prompt)

                # Return JSON response
                return HTTP.Response(200, JSON.json(result))
            else
                return HTTP.Response(404, JSON.json(Dict("error" => "Endpoint not found")))
            end
        catch e
            return HTTP.Response(500, JSON.json(Dict("error" => "Server error: $e")))
        end
    end
end

# Start the server
start_server()