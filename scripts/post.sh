#!/bin/bash

# Post Creator for in-my-bio
# Usage: post.sh create

POSTS_DIR="/Users/Shared/dev/wwwj/projects/in-my-bio/public/posts"
DATA_FILE="/Users/Shared/dev/wwwj/projects/in-my-bio/src/data/posts.json"
INDEX_FILE="/Users/Shared/dev/wwwj/projects/in-my-bio/src/pages/index.astro"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

get_next_number() {
    local count=$(ls -1 "$POSTS_DIR" 2>/dev/null | wc -l)
    printf "%02d" $((count + 1))
}

init_posts_data() {
    if [ ! -f "$DATA_FILE" ]; then
        mkdir -p "$(dirname "$DATA_FILE")"
        echo '{"posts":[]}' > "$DATA_FILE"
    fi
}

create_post() {
    echo -e "${CYAN}=== Create New Post ===${NC}"
    echo ""
    
    # Get post details
    read -p "Title: " title
    read -p "Description: " description
    read -p "URL (redirect URL): " url
    echo ""
    echo -e "${YELLOW}Image drop location:${NC} $POSTS_DIR"
    echo -e "${YELLOW}Naming format:${NC} <number>.<ext> (e.g., 02.gif, 03.png)"
    echo ""
    read -p "Image filename (e.g., 02.gif): " img_name
    
    # Validate image exists
    if [ ! -f "$POSTS_DIR/$img_name" ]; then
        echo -e "${RED}Error: Image not found at $POSTS_DIR/$img_name${NC}"
        return 1
    fi
    
    # Get next number for ID
    local num=$(get_next_number)
    local id="post-$num"
    
    # Add to posts.json
    local temp=$(mktemp)
    jq --arg id "$id" --arg title "$title" --arg desc "$description" --arg url "$url" --arg img "./posts/$img_name" \
        '.posts += [{"id": $id, "title": $title, "description": $desc, "url": $url, "image": $img}]' \
        "$DATA_FILE" > "$temp"
    mv "$temp" "$DATA_FILE"
    
    echo ""
    echo -e "${GREEN}✓ Post created successfully!${NC}"
    echo "  ID: $id"
    echo "  Title: $title"
    echo "  URL: $url"
    echo "  Image: ./posts/$img_name"
    echo ""
    echo "Now update src/pages/index.astro with the new post, then run 'bun run build'"
}

list_posts() {
    init_posts_data
    echo -e "${CYAN}=== Posts List ===${NC}"
    jq -r '.posts[] | "[\(.id)] \(.title)\n  \(.description)\n  URL: \(.url)\n  Image: \(.image)\n"' "$DATA_FILE"
}

case "$1" in
    create)
        init_posts_data
        create_post
        ;;
    list)
        list_posts
        ;;
    *)
        echo -e "${CYAN}Post Creator for in-my-bio${NC}"
        echo ""
        echo "Usage:"
        echo "  post.sh create    - Create new post"
        echo "  post.sh list      - List all posts"
        echo ""
        echo "Workflow:"
        echo "  1. Run: post.sh create"
        echo "  2. Drop image to: $POSTS_DIR"
        echo "  3. Enter image filename when prompted"
        ;;
esac
