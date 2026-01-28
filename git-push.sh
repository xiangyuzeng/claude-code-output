#!/bin/bash
# Git Automation Script for claude-code-output
# Usage: ./git-push.sh "commit message"

set -e

REPO_DIR="/app/claude-code-output"
cd "$REPO_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Claude Code Output - Git Push Automation ===${NC}\n"

# Check if there are changes
if [[ -z $(git status -s) ]]; then
    echo -e "${GREEN}✓ No changes to commit${NC}"
    exit 0
fi

# Show status
echo -e "${YELLOW}Changed files:${NC}"
git status -s
echo ""

# Get commit message
if [ -z "$1" ]; then
    echo -e "${YELLOW}Enter commit message:${NC}"
    read -r COMMIT_MSG
else
    COMMIT_MSG="$1"
fi

# Add all files
echo -e "${YELLOW}Adding files...${NC}"
git add .

# Commit
echo -e "${YELLOW}Committing...${NC}"
git commit -m "${COMMIT_MSG}

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push
echo -e "${YELLOW}Pushing to GitHub...${NC}"
git push origin main

echo -e "\n${GREEN}✓ Successfully pushed to GitHub!${NC}"
echo -e "${GREEN}View at: https://github.com/xiangyuzeng/claude-code-output${NC}"
