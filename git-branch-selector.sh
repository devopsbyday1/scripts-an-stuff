#!/bin/bash
#
# Git Branch Selector
# Version: 1.2.0
# Author: devopsbyday1
# Created: 2025-08-08
# Updated: 2026-01-09
#
# Description:
#   A utility script that helps you search for and checkout git branches easily.
#   It performs the following steps:
#   1. Fetches latest branches from remote
#   2. Auto-detects and checks out default branch (main/master) and pulls latest changes
#   3. Searches for branches matching a search term (case-insensitive grep)
#   4. If one match is found, checks it out automatically
#   5. If multiple matches are found, presents a numbered list with current branch marked
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

# Function to check for uncommitted changes and handle them
handle_uncommitted_changes() {
  if ! git diff-index --quiet HEAD --; then
    warn_msg "You have uncommitted changes in your working directory."
    echo "Options:"
    echo "  1. Stash changes (save them for later)"
    echo "  2. Continue anyway (may fail if there are conflicts)"
    echo "  3. Abort branch switch"
    echo -n "Select an option (1-3): "
    read option
    
    case $option in
      1)
        info_msg "Stashing changes..."
        stash_name="git-branch-selector-stash-$(date +%s)"
        if git stash push -m "$stash_name"; then
          success_msg "Changes stashed successfully. You can restore them later with 'git stash pop'."
          return 0
        else
          error_exit "Failed to stash changes."
        fi
        ;;
      2)
        warn_msg "Continuing with uncommitted changes. This may fail if there are conflicts."
        return 0
        ;;
      3)
        info_msg "Operation aborted by user."
        exit 0
        ;;
      *)
        error_exit "Invalid option. Operation aborted."
        ;;
    esac
  fi
  return 0
}

# Function to safely checkout a branch
safe_checkout() {
  local branch="$1"
  
  # First try simple checkout
  if git checkout "$branch" 2>/dev/null; then
    success_msg "Successfully checked out '$branch'"
    return 0
  fi
  
  # If that fails, try to checkout and track the remote branch
  if git checkout --track "origin/$branch" 2>/dev/null; then
    success_msg "Successfully checked out and tracking remote branch '$branch'"
    return 0
  fi
  
  # If both methods fail, return error
  return 1
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

# Step 1 & 2: Fetch latest branches and detect default branch
info_msg "Fetching latest branches from remote..."
if ! git fetch --prune 2>/dev/null; then
  warn_msg "Failed to fetch from remote. Searching local branches only."
fi

# Try to detect the default branch from remote HEAD
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

# If detection fails, try common branch names
if [ -z "$default_branch" ]; then
  if git show-ref --verify --quiet refs/heads/main; then
    default_branch="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    default_branch="master"
  else
    warn_msg "Could not detect default branch (main/master). Continuing with current branch."
    default_branch=$(git branch --show-current)
  fi
fi

info_msg "Checking out $default_branch branch and pulling latest changes..."

# Check for uncommitted changes before switching
handle_uncommitted_changes

if ! git checkout "$default_branch"; then
  warn_msg "Failed to checkout $default_branch branch. Continuing with current branch."
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

# Step 4: Search for branches (case-insensitive)
info_msg "Searching for branches containing '$search_term'..."
# Use -iE for case-insensitive extended regex
if ! branch_list=$(git branch -a | grep -iE "$search_term" 2>/dev/null); then
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
  
  # Check for uncommitted changes before switching
  handle_uncommitted_changes
  
  if safe_checkout "$branch"; then
    success_msg "Branch checkout complete."
  else
    error_exit "Failed to checkout branch '$branch'. It may not exist locally or remotely."
  fi
else
  info_msg "Multiple matching branches found:"
  current_branch=$(git branch --show-current)
  for i in "${!matching_branches[@]}"; do
    if [ "${matching_branches[$i]}" = "$current_branch" ]; then
      echo -e "  ${GREEN}$((i+1))${NC}. ${matching_branches[$i]} ${YELLOW}(current)${NC}"
    else
      echo -e "  ${GREEN}$((i+1))${NC}. ${matching_branches[$i]}"
    fi
  done
  
  while true; do
    echo -n "Enter number of branch to checkout (1-${#matching_branches[@]}): "
    read selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#matching_branches[@]}" ]; then
      branch="${matching_branches[$((selection-1))]}"
      info_msg "Checking out $branch..."
      
      # Check for uncommitted changes before switching
      handle_uncommitted_changes
      
      if safe_checkout "$branch"; then
        success_msg "Branch checkout complete."
      else
        error_exit "Failed to checkout branch '$branch'. It may not exist locally or remotely."
      fi
      break
    else
      warn_msg "Invalid selection. Please try again."
    fi
  done
fi

success_msg "Done!"