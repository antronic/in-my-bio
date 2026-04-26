#!/bin/bash

# Post Creator for in-my-bio
# Usage: post.sh create
# Supports: PNG, JPG, GIF → GIF | MP4, MOV, WEBM → GIF (animated)

POSTS_DIR=$(dirname $(dirname $0))/public/posts
DATA_FILE=$(dirname $(dirname $0))/src/data/posts.json

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

get_next_number() {
    local count=$(ls -1t "$POSTS_DIR"/*.gif 2>/dev/null | wc -l)
    printf "%02d" $((count + 1))
}

init_posts_data() {
    if [ ! -f "$DATA_FILE" ]; then
        mkdir -p "$(dirname "$DATA_FILE")"
        echo '{"posts":[]}' > "$DATA_FILE"
    fi
}

convert_to_gif() {
    local input=$1
    local output=$2
    
    echo -e "${YELLOW}Converting to GIF...${NC}"
    
    # Check if input is video
    if [[ "$input" =~ \.(mp4|mov|webm)$ ]]; then
        ffmpeg -y -i "$input" -vf "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer" -an "$output" 2>&1 | tail -2
    else
        # Image - copy as-is or convert
        cp "$input" "$output"
    fi
    
    if [ $? -eq 0 ] && [ -f "$output" ]; then
        local size=$(du -h "$output" | cut -f1)
        echo -e "${GREEN}✓ GIF created: $(basename $output) ($size)${NC}"
    else
        echo -e "${RED}✗ Conversion failed${NC}"
        return 1
    fi
}

create_post() {
    echo -e "${CYAN}=== Create New Post ===${NC}"
    echo ""
    
    read -p "Title: " title
    read -p "Description: " description
    read -p "URL (redirect URL): " url
    
    mkdir -p "$POSTS_DIR"
    
    echo ""
    echo -e "${YELLOW}Supported formats:${NC} PNG, JPG, GIF, MP4, MOV, WEBM"
    echo -e "${YELLOW}Drop file to:${NC} $POSTS_DIR"
    echo ""
    read -p "Input filename: " input_name
    
    local input_path="$POSTS_DIR/$input_name"
    if [ ! -f "$input_path" ]; then
        echo -e "${RED}Error: File not found at $input_path${NC}"
        return 1
    fi
    
    local num=$(get_next_number)
    local output_name="post-$num.gif"
    local output_path="$POSTS_DIR/$output_name"
    
    convert_to_gif "$input_path" "$output_path"
    
    local temp=$(mktemp)
    jq --arg id "post-$num" --arg title "$title" --arg desc "$description" --arg url "$url" --arg img "./posts/$output_name" \
        '.posts += [{"id": $id, "title": $title, "description": $desc, "url": $url, "image": $img}]' "$DATA_FILE" > "$temp"
    mv "$temp" "$DATA_FILE"
    
    echo ""
    echo -e "${GREEN}✓ Post created successfully!${NC}"
    echo "  ID: post-$num"
    echo "  Title: $title"
    echo "  URL: $url"
    echo "  Image: ./posts/$output_name"
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
        echo "Supported: PNG, JPG, GIF (copied) | MP4, MOV, WEBM (→ GIF)"
        ;;
esac
