# Total downloads from all repositories

Build, authenticate, and run a Bash script on macOS that counts *release* downloads from all public repositories in a GitHub account.

> **Security note:** do not save or share GitHub personal tokens in scripts, repositories, messages, or screenshots. If a token is exposed, revoke it on GitHub and create a new one.

## Objective

The script iterates through all public repositories of a GitHub user, sums the `download_count` field of the assets from each release, and displays:

- One row per repository with its total number of downloads
- Repositories without releases or without assets with a value of `0`
- A final total that aggregates downloads from all repositories.

GitHub provides public repositories via `GET /users/{username}/repos`, and the releases of each repository via `GET /repos/{owner}/{repo}/releases`. Each asset of a release includes the `download_count` field.

## Dependencies

On macOS, install `jq` and, if not already present on the system, `curl` via Homebrew:

```bash
brew install jq curl
```

Verify they are available:

```bash
command -v jq
command -v curl
```

## Bash Script

Save the following content as `gh-downloads.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./github-release-downloads.sh GITHUB_USER [TOKEN]
#
# To include the GitHub token in the Terminal session before running the script:
#   export GITHUB_TOKEN="ghp_..."
#   ./github-release-downloads.sh perez987
#
# You can also include the token as the second argument of the command:
#   ./github-release-downloads.sh perez987 ghp_...

API_URL="https://api.github.com"
USERNAME="${1:-}"
TOKEN="${2:-${GITHUB_TOKEN:-}}"
PER_PAGE=100

if [[ -z "$USERNAME" ]]; then
  echo "Usage: $0 GITHUB_USER [TOKEN]" >&2
  exit 1
fi

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Error: missing \'$command\'." >&2
    echo "Install it with: brew install $command" >&2
    exit 1
  fi
done

CURL_HEADERS=(
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
)

if [[ -n "$TOKEN" ]]; then
  CURL_HEADERS+=(-H "Authorization: Bearer $TOKEN")
fi

github_get() {
  local url="$1"
  local response
  local status
  local body

  response="$(
    curl --silent --show-error --location \
      --write-out $\'\n%{http_code}\' \
      "${CURL_HEADERS[@]}" \
      "$url"
  )"

  status="$(printf \'%s\n\' "$response" | tail -n 1)"
  body="$(printf \'%s\n\' "$response" | sed \'$d\')"

  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "GitHub API error (HTTP $status):" >&2
    printf \'%s\n\' "$body" | jq -r \'.message // .\' >&2
    exit 1
  fi

  printf \'%s\n\' "$body"
}

get_all_repos() {
  local page=1
  local repos
  local count

  while :; do
    repos="$(
      github_get \
        "$API_URL/users/$USERNAME/repos?type=owner&sort=full_name&direction=asc&per_page=$PER_PAGE&page=$page"
    )"

    count="$(printf \'%s\n\' "$repos" | jq \'length\')"
    [[ "$count" -eq 0 ]] && break

    printf \'%s\n\' "$repos" | jq -r \'.[].name\'

    [[ "$count" -lt "$PER_PAGE" ]] && break
    page=$((page + 1))
  done
}

get_repo_release_downloads() {
  local repo="$1"
  local page=1
  local releases
  local count
  local page_downloads=0
  local total=0

  while :; do
    releases="$(
      github_get \
        "$API_URL/repos/$USERNAME/$repo/releases?per_page=$PER_PAGE&page=$page"
    )"

    count="$(printf \'%s\n\' "$releases" | jq \'length\')"
    [[ "$count" -eq 0 ]] && break

    page_downloads="$(
      printf \'%s\n\' "$releases" |
        jq \'[.[].assets[]?.download_count] | add // 0\'
    )"

    total=$((total + page_downloads))

    [[ "$count" -lt "$PER_PAGE" ]] && break
    page=$((page + 1))
  done

  printf \'%s\n\' "$total"
}

echo "User: $USERNAME"
echo "Querying public repositories and release downloads..."
echo

printf "%-45s %15s\n" "REPOSITORY" "DOWNLOADS"
printf "%-45s %15s\n" "$(printf \'%0.s-\' {1..45})" "$(printf \'%0.s-\' {1..15})"

grand_total=0
repo_count=0
repos_with_releases=0

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue

  downloads="$(get_repo_release_downloads "$repo")"

  printf "%-45s %15s\n" "$repo" "$downloads"

  grand_total=$((grand_total + downloads))
  repo_count=$((repo_count + 1))

  if [[ "$downloads" -gt 0 ]]; then
    repos_with_releases=$((repos_with_releases + 1))
  fi
done < <(get_all_repos)

printf "%-45s %15s\n" "$(printf \'%0.s-\' {1..45})" "$(printf \'%0.s-\' {1..15})"
printf "%-45s %15s\n" "TOTAL" "$grand_total"

echo
echo "Public repositories analyzed: $repo_count"
echo "Repositories with recorded downloads: $repos_with_releases"
```

## Authentication with a Personal Access Token Classic

A Personal Access Token (classic) is used to authenticate requests to the GitHub API. For this script, which queries public data, you can generate a classic token without scopes. This avoids the more restrictive limits of anonymous requests.

### Create the token

1. On GitHub, open **Settings**
2. Go to **Credentials**
3. Open **Personal access tokens (classic)**
4. Click **Generate new token** >> **Generate new token (classic)**
5. Assign a description, for example: `macOS release-downloads script`
6. Choose an appropriate expiration (7, 30, 60, 90 days, custom, or no expiration date)
7. For this public information use, do not select scopes
8. Click **Generate token** and copy it immediately. GitHub does not show the full value again later.

You do not need to select *scopes* to query releases and public repositories. Avoiding unnecessary permissions reduces the impact if the token is lost.

## Usage

Grant execute permission to the script:

```bash
chmod +x gh-downloads.sh
```

### Recommended method: temporary environment variable

Include the GitHub token in the Terminal session before running the script:

```bash
export GITHUB_TOKEN="ghp_PASTE_YOUR_TOKEN_HERE"
./gh-downloads.sh perez987
```

The script takes the token from this expression in the script:

```bash
TOKEN="${2:-${GITHUB_TOKEN:-}}"
```

And adds the HTTP authentication header automatically:

```bash
-H "Authorization: Bearer $TOKEN"
```

When you close the Terminal window, the variable ceases to exist. You can also explicitly remove it:

```bash
unset GITHUB_TOKEN
```

Run the script against the GitHub user:

```bash
./gh-downloads.sh perez987
```

You can also explicitly invoke it with Bash:

```bash
bash gh-downloads.sh perez987
```

> Do not run the script with `sh gh-downloads.sh` because you may get errors.

### Alternative: second argument

You can pass the token as the second argument:

```bash
bash gh-downloads.sh perez987 "ghp_PASTE_YOUR_TOKEN_HERE"
```

```bash
./gh-downloads.sh perez987 "ghp_PASTE_YOUR_TOKEN_HERE"
```

This method works, but is less advisable, as the arguments of an active process may be visible to other processes with sufficient permissions.

### Save the token in `~/.zshrc` (not recommended)

You can save the token in the `~/.zshrc` file so it is always available when you run Terminal, but this is not recommended practice because it is plain text that other processes, not always benign, can access. To do this, add these lines to the `~/.zshrc` file:

```bash
export GITHUB_API_TOKEN=ghp_...
export GITHUB_TOKEN=ghp_...
```

### Save the token in the macOS Keychain

To avoid keeping the token in plain text in `~/.zshrc` or another text file, you can store it in the macOS Keychain:

```bash
security add-generic-password \
  -a "$USER" \
  -s "github-release-downloads" \
  -w "ghp_PASTE_YOUR_TOKEN_HERE" \
  -U
```

To delete the Keychain entry:

```bash
security delete-generic-password \
  -a "$USER" \
  -s "github-release-downloads"
```

## Recommended sequence

After creating a new token and keeping it private:

```bash
export GITHUB_TOKEN="ghp_PASTE_YOUR_TOKEN_HERE"
chmod +x gh-downloads.sh
./gh-downloads.sh perez987
unset GITHUB_TOKEN
```

Also valid:

```bash
export GITHUB_TOKEN="ghp_PASTE_YOUR_TOKEN_HERE"
bash gh-downloads.sh perez987
unset GITHUB_TOKEN
```

## What the result measures

The result sums downloads of ***assets* explicitly attached** to releases: for example, `.dmg`, `.zip`, `.tar.gz`, and binaries published as *assets*: ZIP, DMG, etc.

It does not necessarily represent:

- Repository clones
- Repository visits or traffic
- Installations made via Homebrew, npm, pip, or other package managers
- Downloads of source files that GitHub automatically generates for a *release*, when they are not *assets* explicitly published and counted as such.

## Example output

```text
User: perez987
Querying public repositories and release asset downloads...

REPOSITORY                                          DOWNLOADS
--------------------------------------------- ---------------
About-This-Hack                                          1808
AgendaT                                                   102
Apple-Secure-Boot-and-Vault-with-OpenCore                   0
AppleHDA-back-on-macOS-26-Tahoe                             0
Audiometry                                                 92
DMGBuildNotarize                                          336
DockProgress-test                                          54
DownloadFullInstaller                                    1776
Easy-Ethernet-Icon                                          0
Fenvi-wifi-back-on-Sonoma-Sequoia-Tahoe                     0
...
--------------------------------------------------- ---------------
TOTAL                                                   17636

Public repositories analyzed: 42
Repositories with recorded downloads: 20
```
