#!/bin/bash

# Project Tracker Script - Local Project Directory Based
TRACKER_FILE=".project-tracker.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

get_project_name() {
    local dir="$1"
    if [ -f "$dir/package.json" ]; then
        jq -r '.name // .project // "unnamed"' "$dir/package.json" 2>/dev/null
    elif [ -d "$dir/.git" ]; then
        basename "$(git -C "$dir" rev-parse --show-toplevel)" 2>/dev/null
    else
        basename "$dir"
    fi
}

init_tracker() {
    local dir="${1:-.}"
    local project_name=$(get_project_name "$dir")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$dir/$TRACKER_FILE" << EOF
{
  "name": "$project_name",
  "path": "$dir",
  "status": "active",
  "tags": [],
  "createdAt": "$timestamp",
  "updatedAt": "$timestamp"
}
EOF
    echo -e "${GREEN}✓ Initialized: $project_name${NC}"
}

add_project() {
    local status="${2:-active}"
    local dir="${1:-.}"
    
    if [ -f "$dir/$TRACKER_FILE" ]; then
        echo -e "${YELLOW}Tracker exists. Use 'update' instead.${NC}"
        return 1
    fi
    
    local project_name=$(get_project_name "$dir")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local tags_json="[]"
    
    cat > "$dir/$TRACKER_FILE" << EOF
{
  "name": "$project_name",
  "path": "$dir",
  "status": "$status",
  "tags": $tags_json,
  "createdAt": "$timestamp",
  "updatedAt": "$timestamp"
}
EOF
    echo -e "${GREEN}✓ Added: $project_name ($status)${NC}"
}

update_project() {
    local status="$2"
    local dir="${1:-.}"
    
    if [ ! -f "$dir/$TRACKER_FILE" ]; then
        echo -e "${RED}No tracker in $dir${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp=$(mktemp)
    jq --arg status "$status" --arg ts "$timestamp" \
        '.status = $status | .updatedAt = $ts' "$dir/$TRACKER_FILE" > "$temp"
    mv "$temp" "$dir/$TRACKER_FILE"
    
    local name=$(jq -r '.name' "$dir/$TRACKER_FILE")
    echo -e "${GREEN}✓ Updated: $name → $status${NC}"
}

show_status() {
    local dir="${1:-.}"
    
    if [ ! -f "$dir/$TRACKER_FILE" ]; then
        echo -e "${YELLOW}No tracker in $dir${NC}"
        return 1
    fi
    
    local name status tags created updated
    name=$(jq -r '.name' "$dir/$TRACKER_FILE")
    status=$(jq -r '.status' "$dir/$TRACKER_FILE")
    tags=$(jq -r '.tags | join(", ")' "$dir/$TRACKER_FILE")
    created=$(jq -r '.createdAt' "$dir/$TRACKER_FILE")
    updated=$(jq -r '.updatedAt' "$dir/$TRACKER_FILE")
    
    case "$status" in
        active) color=$GREEN ;;
        paused) color=$YELLOW ;;
        completed) color=$BLUE ;;
        *) color=$NC ;;
    esac
    
    echo -e "${CYAN}Project:${NC} $name"
    echo -e "${CYAN}Status:${NC} ${color}$status${NC}"
    echo -e "${CYAN}Tags:${NC} $tags"
    echo -e "${CYAN}Path:${NC} $(realpath "$dir")"
}

list_projects() {
    local search_dir="${1:-.}"
    local filter="$2"
    
    if [ ! -d "$search_dir" ]; then
        echo -e "${RED}Directory not found: $search_dir${NC}"
        return 1
    fi
    
    # Get physical path
    local physical_dir
    if command -v realpath &> /dev/null; then
        physical_dir=$(realpath "$search_dir" 2>/dev/null || echo "$search_dir")
    else
        physical_dir="$search_dir"
    fi
    
    echo -e "${CYAN}Scanning: $physical_dir${NC}"
    
    # Check current level + 1 subdirectory level (includes projects with tracker at root)
    local trackers=$(find "$physical_dir" -maxdepth 2 -name "$TRACKER_FILE" -type f 2>/dev/null)
    
    if [ -z "$trackers" ]; then
        echo -e "${YELLOW}No trackers found${NC}"
        return
    fi
    
    printf "${CYAN}%-30s %-12s %-35s %s${NC}\n" "PROJECT" "STATUS" "TAGS" "PATH"
    echo "----------------------------------------------------------------------------------------"
    
    for tracker in $trackers; do
        [ -z "$tracker" ] && continue
        dir=$(dirname "$tracker")
        name=$(jq -r '.name' "$tracker")
        status=$(jq -r '.status' "$tracker")
        tags=$(jq -r '.tags | join(", ")' "$tracker")
        
        # Apply filter
        if [ -n "$filter" ]; then
            if [[ "$name" != *"$filter"* ]] && [[ "$status" != *"$filter"* ]]; then
                continue
            fi
        fi
        
        case "$status" in
            active) color=$GREEN ;;
            paused) color=$YELLOW ;;
            completed) color=$BLUE ;;
            archived) color=$NC ;;
            *) color=$NC ;;
        esac
        
        printf "%-30s ${color}%-12s${NC} %-35s %s\n" "$name" "$status" "$tags" "$dir"
    done
}

find_projects() {
    local keyword="$1"
    local search_dirs=("$HOME/projects" "$HOME/dev" "$HOME/workspace" "/Users/Shared/dev")
    
    local found=0
    printf "\n${CYAN}%-30s %-12s %s${NC}\n" "PROJECT" "STATUS" "PATH"
    echo "----------------------------------------------------------------"
    
    for search_dir in "${search_dirs[@]}"; do
        [ ! -d "$search_dir" ] && continue
        for tracker in $(find "$search_dir" -name "$TRACKER_FILE" -type f 2>/dev/null); do
            [ -z "$tracker" ] && continue
            dir=$(dirname "$tracker")
            name=$(jq -r '.name' "$tracker")
            status=$(jq -r '.status' "$tracker")
            
            if [[ "$name" == *"$keyword"* ]] || [[ "$dir" == *"$keyword"* ]]; then
                found=1
                case "$status" in
                    active) color=$GREEN ;;
                    paused) color=$YELLOW ;;
                    completed) color=$BLUE ;;
                    *) color=$NC ;;
                esac
                printf "%-30s ${color}%-12s${NC} %s\n" "$name" "$status" "$dir"
            fi
        done
    done
    
    [ $found -eq 0 ] && echo -e "${YELLOW}No matches for '$keyword'${NC}"
}

add_tag() {
    local dir="${1:-.}"
    local tag="$2"
    
    if [ ! -f "$dir/$TRACKER_FILE" ]; then
        echo -e "${RED}No tracker in $dir${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp=$(mktemp)
    jq --arg tag "$tag" --arg ts "$timestamp" \
        '.tags += [$tag] | .updatedAt = $ts' "$dir/$TRACKER_FILE" > "$temp"
    mv "$temp" "$dir/$TRACKER_FILE"
    
    echo -e "${GREEN}✓ Added tag: $tag${NC}"
}

case "$1" in
    init) init_tracker "$2" ;;
    add) add_project "$2" "$3" ;;
    update) update_project "$2" "$3" ;;
    status) show_status "$2" ;;
    list) list_projects "$2" "$3" ;;
    find) find_projects "$2" ;;
    tag) add_tag "$2" "$3" ;;
    *)
        echo -e "${CYAN}Project Tracker${NC}"
        echo "Usage:"
        echo "  track init [dir]              Initialize"
        echo "  track add [dir] <status>      Add project"
        echo "  track update [dir] <status>   Update status"
        echo "  track status [dir]            Show status"
        echo "  track list [dir] [filter]     List projects (current + 1 level)"
        echo "  track find <keyword>          Find projects"
        echo "  track tag [dir] <tag>         Add tag"
        ;;
esac
