#!/bin/bash
# GitHub Push Script
# 1. Edit this file and replace YOUR_TOKEN_HERE with your actual token
# 2. Run: chmod +x push-to-github.sh && ./push-to-github.sh

# >>> REPLACE THESE VALUES <<<
GH_TOKEN="YOUR_TOKEN_HERE"
GH_USER="bibekdhakal5"
REPO="TimeDisplayApp"
BRANCH="master"
# <<< END REPLACE >>>

cd /root/App

# Set remote with token authentication
git remote set-url origin https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${REPO}.git

# Push
git push -u origin ${BRANCH}

# Clean up
unset GH_TOKEN
echo "Done!"