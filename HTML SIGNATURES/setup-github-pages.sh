#!/usr/bin/env bash
# PowerSol email-signature logo hosting — GitHub Pages setup
#
# Run this in a normal terminal on your own PC (PowerShell's "Git Bash", WSL,
# or wherever you already have — or can log into — GitHub). It will NOT work
# inside a sandboxed shell that has no internet access.
#
# What it does:
#   1. Checks for git and the GitHub CLI (gh), and makes sure you're logged in.
#   2. Creates a small local folder with your logo PNGs.
#   3. Creates a new PUBLIC GitHub repo called "powersol-signature-assets"
#      and pushes the images to it in one step.
#   4. Turns on GitHub Pages for that repo.
#   5. Prints the final public URL for every image, and updates the two
#      signature HTML files to use them automatically.
#
# Nothing here ever asks you to type a password or token into a chat —
# authentication happens via GitHub's own browser login (gh auth login).

set -euo pipefail

REPO_NAME="powersol-signature-assets"
WORK_DIR="$HOME/PowerSol/email-signature-assets"
SIG_FILES=("$HOME/PowerSol/signature_rob.html" "$HOME/PowerSol/signature.html")

echo "== 1. Checking prerequisites =="

if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed. Install Git for Windows from https://git-scm.com/download/win and re-run this script."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "The GitHub CLI (gh) is not installed."
  echo "Install it, then re-run this script:"
  echo "  Windows (PowerShell):  winget install --id GitHub.cli"
  echo "  macOS:                 brew install gh"
  echo "  Or download directly:  https://cli.github.com"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "You're not logged into GitHub yet. Starting the login now —"
  echo "a browser window will open; sign in and approve it, then this script continues."
  gh auth login --hostname github.com --git-protocol https --web
fi

GH_USER=$(gh api user -q .login)
echo "Logged in as: $GH_USER"

echo "== 2. Preparing local files =="
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "This folder is: $WORK_DIR"
echo "Make sure your logo PNGs are in here before continuing (26 files):"
echo "  powersol-logo.png"
echo "  victron-logo.png            hella-marine-logo.png       sleipner-logo.png"
echo "  oceanled-logo.png           seaview-blinds-logo.png     arco-logo.png"
echo "  carling-logo.png            frigus-wema-logo.png        mg-energy-systems-logo.png"
echo "  blue-sea-systems-logo.png   bep-logo.png                czone-logo.png"
echo "  marinco-logo.png            lenco-logo.png               ancor-logo.png"
echo "  rim-drive-logo.png          ruuvi-logo.png               scanstrut-logo.png"
echo "  shurflo-logo.png            silentwind-logo.png          spectra-watermakers-logo.png"
echo "  sterling-logo.png           watt-sea-logo.png            balmar-logo.png"
echo "  bellmarine-logo.png"
echo
echo "(The full list with each brand's website is in supplier-logo-checklist.csv"
echo " in this same folder, if you need a reminder of what goes with what.)"
echo
read -rp "Press Enter once the PNG files are in $WORK_DIR ..." _

shopt -s nullglob
PNGS=(*.png)
if [ ${#PNGS[@]} -eq 0 ]; then
  echo "No .png files found in $WORK_DIR — add them and re-run."
  exit 1
fi
echo "Found: ${PNGS[*]}"

echo "== 3. Creating the GitHub repo and pushing =="
if [ ! -d .git ]; then
  git init -q
  git branch -M main
fi
git add -- *.png
if ! git diff --cached --quiet; then
  git -c user.email="$GH_USER@users.noreply.github.com" -c user.name="$GH_USER" \
    commit -q -m "Add PowerSol email signature logos"
else
  echo "Nothing new to commit."
fi

if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "Repo $GH_USER/$REPO_NAME already exists — pushing to it."
  git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git" 2>/dev/null || true
  git push -u origin main
else
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
fi

echo "== 4. Enabling GitHub Pages =="
gh api -X POST "repos/$GH_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || \
  echo "(Pages may already be enabled — that's fine.)"

BASE_URL="https://$GH_USER.github.io/$REPO_NAME"
echo
echo "== Done. Your hosted image URLs =="
for f in "${PNGS[@]}"; do
  echo "  $BASE_URL/$f"
done

echo
echo "== 5. Updating signature files =="
for sig in "${SIG_FILES[@]}"; do
  if [ -f "$sig" ]; then
    sed -i.bak "s#REPLACE-WITH-YOUR-HOSTED-URL#${BASE_URL}#g" "$sig"
    echo "Updated: $sig"
  fi
done

echo
echo "All set. It can take a minute or two for GitHub Pages to go live the first time —"
echo "if an image URL 404s immediately, just wait a minute and refresh."
