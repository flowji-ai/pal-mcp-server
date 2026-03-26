#!/usr/bin/env bash

# backfill-doc-status.sh
#
# Purpose: Backfill document status fields in meta.json files
#
# This script scans all meta.json files and adds status fields to document
# entries that are missing them. This is needed for the Phase derivation
# logic in the spec registry system (Spec 030).
#
# Document status is inferred from file existence and content:
#   - File exists with content (>100 bytes) → status = "complete"
#   - File exists but minimal/empty → status = "draft"
#   - File doesn't exist → status = "planned"
#
# Usage: ./backfill-doc-status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Counters
files_updated=0
statuses_added=0

# Function to check file size
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        wc -c < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

# Function to infer status from file
infer_status() {
    local file_path="$1"
    local size=$(get_file_size "$file_path")

    if [[ ! -f "$file_path" ]]; then
        echo "planned"
    elif [[ $size -gt 100 ]]; then
        echo "complete"
    else
        echo "draft"
    fi
}

# Function to process a single meta.json file
process_meta_file() {
    local meta_file="$1"
    local spec_dir=$(dirname "$meta_file")
    local modified=false
    local temp_file="${meta_file}.tmp"

    # Check if documents object exists
    if ! jq -e '.documents' "$meta_file" &> /dev/null; then
        return 0
    fi

    # Get list of documents
    local docs=$(jq -r '.documents | keys[]' "$meta_file" 2>/dev/null || echo "")

    if [[ -z "$docs" ]]; then
        return 0
    fi

    # Start with original content
    cp "$meta_file" "$temp_file"

    # Process each document
    while IFS= read -r doc_name; do
        # Check if status field exists
        local has_status=$(jq -r ".documents[\"$doc_name\"] | has(\"status\")" "$temp_file")

        if [[ "$has_status" == "false" ]]; then
            # Implementation summaries are immutable — always completed
            if [[ "$doc_name" == implementation-summaries/* ]]; then
                local inferred_status="completed"
            else
                local doc_path="${spec_dir}/${doc_name}"
                local inferred_status=$(infer_status "$doc_path")
            fi

            # Add status field to this document entry
            jq ".documents[\"$doc_name\"].status = \"$inferred_status\"" "$temp_file" > "${temp_file}.2"
            mv "${temp_file}.2" "$temp_file"

            modified=true
            ((statuses_added++))
        fi
    done <<< "$docs"

    # If we made changes, replace the original file
    if [[ "$modified" == "true" ]]; then
        mv "$temp_file" "$meta_file"
        ((files_updated++))
    else
        rm "$temp_file"
    fi
}

echo "Backfilling document status fields in meta.json files..."
echo ""

# Process active specs
echo "Scanning spectri/specs/ directory..."
for meta_file in spectri/specs/*/meta.json; do
    if [[ -f "$meta_file" ]]; then
        process_meta_file "$meta_file"
    fi
done

# Process deployed specs
if [[ -d "spectri/specs/04-deployed" ]]; then
    echo "Scanning spectri/specs/04-deployed/ directory..."
    for meta_file in spectri/specs/04-deployed/*/meta.json; do
        if [[ -f "$meta_file" ]]; then
            process_meta_file "$meta_file"
        fi
    done
fi

# Process archived specs (if they exist)
if [[ -d "spectri/specs/05-archived" ]]; then
    echo "Scanning spectri/specs/05-archived/ directory..."
    for meta_file in spectri/specs/05-archived/*/meta.json; do
        if [[ -f "$meta_file" ]]; then
            process_meta_file "$meta_file"
        fi
    done
fi

echo ""
echo "✓ Backfill complete!"
echo "  Files updated: $files_updated"
echo "  Status fields added: $statuses_added"
