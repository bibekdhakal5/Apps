#!/usr/bin/env bash
set -e

# Load your existing token
if [ ! -f .env ]; then
  echo "ERROR: No .env file found in this folder."
  exit 1
fi

set -a
source .env
set +a

if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: Set GITHUB_TOKEN in your .env file."
  exit 1
fi

command -v curl >/dev/null
command -v git >/dev/null

# Use the current folder name as the repository name
REPO=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' |
  sed 's/[^a-z0-9._-]/-/g')

# Protect environment secrets
touch .gitignore
grep -qxF '.env' .gitignore || echo '.env' >> .gitignore
grep -qxF 'create-repo.sh' .gitignore ||
  echo 'create-repo.sh' >> .gitignore

# Initialize Git if needed
if [ ! -d .git ]; then
  git init
fi

# Make the first commit
git add .
if ! git diff --cached --quiet; then
  git -c user.name="GitHub User" \
      -c user.email="github-user@users.noreply.github.com" \
      commit -m "Initial commit"
fi

# Create the private GitHub repository
RESPONSE=$(curl -fsS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO\",\"private\":true}" ) || {
    echo "Repository creation failed. Check your token permissions."
    exit 1
  }

OWNER=$(printf '%s' "$RESPONSE" |
  python -c 'import json,sys; print(json.load(sys.stdin)["owner"]["login"])')

URL="https://github.com/$OWNER/$REPO.git"

# Connect the repository and push without storing the token in the URL
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$URL"
else
  git remote add origin "$URL"
fi

git branch -M main
git -c http.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')" push -u origin main

echo "Success! Your private repository is https://github.com/$OWNER/$REPO"
