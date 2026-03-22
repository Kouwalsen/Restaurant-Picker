using HTTP, JSON

# Load SDK
directory = raw"C:\Users\KYZMA\Downloads\imessage-kit-main"
sdk_path = joinpath(directory, "imessage-kit-main", "src", "core", "sdk.ts")

# Intent recognition keywords
const SEARCH_KEYWORDS = ["find", "search", "looking for", "want", "need", "show", "suggest", "recommend", "pick"]
const RESTAURANT_KEYWORDS = ["restaurant", "food", "hungry", "eating", "dine", "dinner", "lunch", "breakfast", "cuisine", "place", "eat"]

function detect_restaurant_intent(user_input::String)::Tuple{Bool, String}
    """
    Analyzes user input to detect restaurant search intent.
    Returns (is_restaurant_search::Bool, search_query::String)
    """
    lower_input = lowercase(user_input)
    
    # Check if input contains restaurant-related keywords
    has_search = any(keyword in lower_input for keyword in SEARCH_KEYWORDS)
    has_restaurant = any(keyword in lower_input for keyword in RESTAURANT_KEYWORDS)
    
    # If both action (search) and subject (restaurant) are present, it's a restaurant query
    if has_search && has_restaurant
        return (true, user_input)
    end
    
    # Fallback: if only restaurant keywords exist, assume restaurant search
    if has_restaurant
        return (true, user_input)
    end
    
    # Not a restaurant search
    return (false, "")
end

function extract_search_parameters(user_input::String)::String
    """
    Extracts cuisine type or location from user input.
    Example: "find me Italian restaurants" -> "Italian"
    """
    cuisine_keywords = ["italian", "chinese", "japanese", "mexican", "thai", "french", "indian", "pizza", "burger", "sushi", "taco"]
    lower_input = lowercase(user_input)
    
    for cuisine in cuisine_keywords
        if cuisine in lower_input
            return cuisine
        end
    end
    
    # If no specific cuisine, use full input as search query
    return user_input
end

# Main program
println("🍽️ Restaurant Picker initializing...")

# Get user input
user_prompt = Base.prompt("What are you craving? (e.g., 'find Italian restaurants', 'I want pizza', 'show me lunch spots')")

# Detect intent
is_restaurant_search, _ = detect_restaurant_intent(user_prompt)

if !is_restaurant_search
    println("❌ I didn't understand. Please try asking for a restaurant (e.g., 'find me a restaurant', 'I'm hungry', 'show Italian food')")
else
    # Extract search parameters
    search_query = extract_search_parameters(user_prompt)
    println("✓ Searching for: $search_query")
    
    # Query OpenTable API
    try
        url = "https://opentable.com/api/restaurants?query=$(HTTP.escapeuri(search_query))"
        response = HTTP.get(url)
        data = JSON.parse(String(response.body))
        
        # Extract restaurant info
        if haskey(data, "restaurants") && !isempty(data["restaurants"])
            restaurant = data["restaurants"][1]
            
            # Display results
            println("\n🍽️ Found Restaurant:")
            println("   Name: $(restaurant["name"])")
            println("   Cuisine: $(get(restaurant, "cuisine", "N/A"))")
            println("   Location: $(get(restaurant, "location", "N/A"))")
            println("   Rating: $(get(restaurant, "rating", "N/A")) ⭐")
        else
            println("❌ No restaurants found for: $search_query")
        end
    catch e
        println("❌ Error: $e")
    end
end