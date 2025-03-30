#!/bin/bash

# Define the containers
containers=("validator-0-fendermint" "validator-1-fendermint" "validator-2-fendermint")

# Function to build search pattern from arguments
build_search_pattern() {
    local pattern=""
    for term in "$@"; do
        if [ -z "$pattern" ]; then
            pattern="$term"
        else
            pattern="$pattern|$term"
        fi
    done
    echo "$pattern"
}

# Check if we have a container number and at least one search term
if [ $# -lt 2 ]; then
    echo "Usage: $0 <container_number> <search_term1> [search_term2] [search_term3] ..."
    echo "  container_number: 0, 1, or 2"
    echo "Example: $0 0 'end block' warn error"
    echo ""
    echo "Available containers:"
    for i in "${!containers[@]}"; do
        echo "  $i: ${containers[$i]}"
    done
    exit 1
fi

# Extract container number and validate
container_num=$1
shift

if ! [[ "$container_num" =~ ^[0-9]+$ ]] || [ "$container_num" -lt 0 ] || [ "$container_num" -ge ${#containers[@]} ]; then
    echo "Error: Invalid container number. Must be between 0 and $((${#containers[@]}-1))"
    echo "Available containers:"
    for i in "${!containers[@]}"; do
        echo "  $i: ${containers[$i]}"
    done
    exit 1
fi

container=${containers[$container_num]}
search_pattern=$(build_search_pattern "$@")

echo "Monitoring logs for container: $container"
echo "Search pattern: '$search_pattern'"

# Run docker logs for the selected container
exec docker logs -f --tail 0 "$container" 2>&1 | grep --line-buffered -E "$search_pattern"
