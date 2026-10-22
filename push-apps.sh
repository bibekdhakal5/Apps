#!/bin/bash
set -e

source .env
[ -n "$GITHUB_TOKEN" ] || {
  echo "GITHUB_TOKEN is missing from .env"
  exit 1
}

OWNER=$(curl -fsS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user |
  python -c 'import json,sys; print(json.load(sys.stdin)["login"])')

URL="https://github.com/$OWNER/Apps.git"

# Verify the existing repository
curl -fsS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/Apps" >/dev/null

# Protect the token file
touch .gitignore
grep -qxF '.env' .gitignore || echo '.env' >> .gitignore

git init
git rm --cached --ignore-unmatch .env
git add -A

if ! git diff --cached --quiet; then
  git -c user.name="$OWNER" \
      -c user.email="$OWNER@users.noreply.github.com" \
      commit -m "Update project"
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$URL"
else
  git remote add origin "$URL"
fi

git branch -M main

git -c http.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')" push -u origin main

echo "Success: https://github.com/$OWNER/Apps"
