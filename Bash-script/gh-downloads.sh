#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./github-release-downloads.sh USUARIO_GITHUB [TOKEN]
#
# Para incluir el token GitHub en la sesión de Terminal antes de ejecutar el script:
#   export GITHUB_TOKEN="ghp_..."
#   ./github-release-downloads.sh perez987
#
# También puedes incluir el token como segundo argumento del comando:
#   ./github-release-downloads.sh perez987 ghp...

API_URL="https://api.github.com"
USERNAME="${1:-}"
TOKEN="${2:-${GITHUB_TOKEN:-}}"
PER_PAGE=100

if [[ -z "$USERNAME" ]]; then
  echo "Uso: $0 USUARIO_GITHUB [TOKEN]" >&2
  exit 1
fi

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Error: falta '$command'." >&2
    echo "Instálalo con: brew install $command" >&2
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
      --write-out $'\n%{http_code}' \
      "${CURL_HEADERS[@]}" \
      "$url"
  )"

  status="$(printf '%s\n' "$response" | tail -n 1)"
  body="$(printf '%s\n' "$response" | sed '$d')"

  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "Error en GitHub API (HTTP $status):" >&2
    printf '%s\n' "$body" | jq -r '.message // .' >&2
    exit 1
  fi

  printf '%s\n' "$body"
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

    count="$(printf '%s\n' "$repos" | jq 'length')"
    [[ "$count" -eq 0 ]] && break

    printf '%s\n' "$repos" | jq -r '.[].name'

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

    count="$(printf '%s\n' "$releases" | jq 'length')"
    [[ "$count" -eq 0 ]] && break

    page_downloads="$(
      printf '%s\n' "$releases" |
        jq '[.[].assets[]?.download_count] | add // 0'
    )"

    total=$((total + page_downloads))

    [[ "$count" -lt "$PER_PAGE" ]] && break
    page=$((page + 1))
  done

  printf '%s\n' "$total"
}

echo "Usuario: $USERNAME"
echo "Consultando repositorios públicos y descargas de releases..."
echo

printf "%-45s %15s\n" "REPOSITORIO" "DESCARGAS"
printf "%-45s %15s\n" "$(printf '%0.s-' {1..45})" "$(printf '%0.s-' {1..15})"

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

printf "%-45s %15s\n" "$(printf '%0.s-' {1..45})" "$(printf '%0.s-' {1..15})"
printf "%-45s %15s\n" "TOTAL" "$grand_total"

echo
echo "Repositorios públicos analizados: $repo_count"
echo "Repositorios con descargas registradas: $repos_with_releases"