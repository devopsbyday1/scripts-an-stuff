#!/bin/bash
#
# Git Branch Selector
# Version: 1.0.0
# Author: devopsbyday1
# Created: 2025-08-07
#
# Description:
#   A utility script that helps you search for and checkout git branches easily.
#   It performs the following steps:
#   1. Checks out master branch and pulls latest changes
#   2. Searches for branches matching a search term (via grep)
#   3. If one match is found, checks it out automatically
#   4. If multiple matches are found, presents a numbered list for selection
#
# Usage:
#   ./git-branch-selector.sh [SEARCH_TERM]
#
# Examples:
#   ./git-branch-selector.sh feature      # Search for branches containing "feature"
#   ./git-branch-selector.sh JIRA-123     # Search for branches with a JIRA ticket number
#   ./git-branch-selector.sh              # Run without arguments to be prompted for a search term
#
# Installation:
#   1. Save this file as git-branch-selector.sh
#   2. Make executable: chmod +x git-branch-selector.sh
#   3. Optional: move to a directory in your PATH to use from anywhere
#      Example: sudo cp git-branch-selector.sh /usr/local/bin/git-branch-selector
#      OR: add it as an alias in your bashrc or zshrc file
#

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print error messages and exit
error_exit() {
  echo -e "${RED}ERROR: $1${NC}" >&2
  exit 1
}

# Function to print success messages
success_msg() {
  echo -e "${GREEN}$1${NC}"
}

# Function to print info messages
info_msg() {
  echo -e "${BLUE}$1${NC}"
}

# Function to print warning messages
warn_msg() {
  echo -e "${YELLOW}$1${NC}"
}

# Function to strip 'remotes/origin/' prefix and keep unique branch names
strip_remote_prefix() {
  sed 's|remotes/origin/||' | sort | uniq
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  error_exit "Not in a git repository. Please run this script from within a git repository."
fi

# Display help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  cat << EOF
Git Branch Selector

Usage:
  ./git-branch-selector.sh [SEARCH_TERM]

Examples:
  ./git-branch-selector.sh feature      # Search for branches containing "feature"
  ./git-branch-selector.sh JIRA-123     # Search for branches with a JIRA ticket number
  ./git-branch-selector.sh              # Run without arguments to be prompted

Options:
  -h, --help    Show this help message
EOF
  exit 0
fi

# Step 1 & 2: Checkout master and pull
info_msg "Checking out master branch and pulling latest changes..."
if ! git checkout master; then
  warn_msg "Failed to checkout master branch. Continuing with current branch."
fi

if ! git pull; then
  warn_msg "Failed to pull latest changes. Continuing with current state."
fi

# Step 3: Get search term from argument or prompt
if [ -n "$1" ]; then
  search_term="$1"
  info_msg "Using search term: '$search_term'"
else
  echo -n "Enter search term for branch name: "
  read search_term
  if [ -z "$search_term" ]; then
    error_exit "No search term provided. Exiting."
  fi
fi

# Step 4: Search for branches
info_msg "Searching for branches containing '$search_term'..."
# Use -E for extended regex and wrap in try/catch
if ! branch_list=$(git branch -a | grep -E "$search_term" 2>/dev/null); then
  error_exit "No branches found matching '$search_term'"
fi

matching_branches=($(echo "$branch_list" | strip_remote_prefix))

# Step 5 & 6: Handle branch selection and checkout
if [ ${#matching_branches[@]} -eq 0 ]; then
  error_exit "No matching branches found."
elif [ ${#matching_branches[@]} -eq 1 ]; then
  branch="${matching_branches[0]}"
  success_msg "Found one matching branch: $branch"
  info_msg "Checking out $branch..."
  
  if git checkout "$branch"; then
    success_msg "Successfully checked out '$branch'"
  else
    # Try to create the branch tracking the remote
    warn_msg "Direct checkout failed. Trying to create tracking branch..."
    if git checkout -b "$branch" "origin/$branch"; then
      success_msg "Successfully created and checked out tracking branch '$branch'"
    else
      error_exit "Failed to checkout branch '$branch'. It may not exist locally or remotely."
    fi
  fi
else
  info_msg "Multiple matching branches found:"
  for i in "${!matching_branches[@]}"; do
    echo -e "  ${GREEN}$((i+1))${NC}. ${matching_branches[$i]}"
  done
  
  while true; do
    echo -n "Enter number of branch to checkout (1-${#matching_branches[@]}): "
    read selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#matching_branches[@]}" ]; then
      branch="${matching_branches[$((selection-1))]}"
      info_msg "Checking out $branch..."
      
      if git checkout "$branch"; then
        success_msg "Successfully checked out '$branch'"
      else
        # Try to create the branch tracking the remote
        warn_msg "Direct checkout failed. Trying to create tracking branch..."
        if git checkout -b "$branch" "origin/$branch"; then
          success_msg "Successfully created and checked out tracking branch '$branch'"
        else
          error_exit "Failed to checkout branch '$branch'. It may not exist locally or remotely."
        fi
      fi
      break
    else
      warn_msg "Invalid selection. Please try again."
    fi
  done
fi

success_msg "Done!"