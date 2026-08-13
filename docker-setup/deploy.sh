#!/usr/bin/env bash
# Purpose: Safely deploy application code to an existing Frappe site.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/runtime.sh
source "$SCRIPT_DIR/lib/runtime.sh"
init_script_logging "$SCRIPT_DIR" "deploy"

COMMAND=""
YES=0
DEPLOY_ACTIVE=0
CANDIDATE_IMAGE=""
RELEASE_FILE=""

usage() {
    cat <<'EOF'
Usage: ./deploy.sh <check|plan|apply|verify> [--yes]

Commands:
  check    Validate configuration, source access, Compose, and the running site.
  plan     Show the source revisions and deployment steps without changing state.
  apply    Build, back up, migrate, restart, and verify an existing site.
  verify   Verify the currently running services and site database connection.

Options:
  --yes, -y  Skip the typed DEPLOY confirmation for trusted automation.
  --help, -h Show this help message.
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            check|plan|apply|verify)
                if [ -n "$COMMAND" ]; then
                    echo "Error: Specify only one command."
                    exit 1
                fi
                COMMAND="$1"
                ;;
            --yes|-y) YES=1 ;;
            --help|-h) usage; exit 0 ;;
            *) echo "Error: Unknown argument: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [ -z "$COMMAND" ]; then
        usage
        exit 1
    fi
}

apps_require_github_token() {
    jq -e '.[] | select(.private == true)' "$SCRIPT_DIR/apps.json" >/dev/null
}

git_with_github_auth() {
    local authorization

    if [ -z "${GITHUB_TOKEN:-}" ]; then
        GIT_TERMINAL_PROMPT=0 git "$@"
        return
    fi

    authorization="$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')"
    GIT_TERMINAL_PROMPT=0 \
        GIT_CONFIG_COUNT=1 \
        GIT_CONFIG_KEY_0='http.https://github.com/.extraheader' \
        GIT_CONFIG_VALUE_0="AUTHORIZATION: basic $authorization" \
        git "$@"
}

redact_github_token() {
    python3 -c '
import os
import sys

token = os.environ.get("GITHUB_TOKEN", "")
for line in sys.stdin:
    sys.stdout.write(line.replace(token, "<redacted>") if token else line)
'
}

validate_app_configuration() {
    if [ ! -f "$SCRIPT_DIR/apps.json" ] || ! jq -e 'type == "array"' "$SCRIPT_DIR/apps.json" >/dev/null; then
        echo "Error: apps.json is missing or is not a valid JSON array."
        return 1
    fi
    if jq -e '.[] | select((.url // "") | test("^https://[^/]+@github\\.com/"))' \
        "$SCRIPT_DIR/apps.json" >/dev/null; then
        echo "Error: apps.json contains a credential-bearing GitHub URL."
        echo "Use a clean GitHub URL, private=true, and GITHUB_TOKEN in .env."
        return 1
    fi
    if apps_require_github_token && [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "Error: GITHUB_TOKEN is required by a private apps.json entry."
        return 1
    fi
}

resolve_source_revisions() {
    local branch
    local commit
    local name
    local remote_refs
    local row
    local url

    RELEASE_FILE="$(mktemp)"
    while IFS= read -r row; do
        name="$(printf '%s' "$row" | jq -r '.name // (.url | split("/") | last | sub("\\.git$"; ""))')"
        url="$(printf '%s' "$row" | jq -r '.url')"
        branch="$(printf '%s' "$row" | jq -r '.branch // "main"')"
        if ! remote_refs="$(git_with_github_auth ls-remote --exit-code "$url" \
            "refs/heads/$branch" "refs/tags/$branch" "refs/tags/$branch^{}")"; then
            echo "Error: Cannot resolve '$name' branch/tag '$branch' at $url."
            return 1
        fi
        commit="$(printf '%s\n' "$remote_refs" | awk -v ref="$branch" '
            $2 == "refs/heads/" ref { head = $1 }
            $2 == "refs/tags/" ref { tag = $1 }
            $2 == "refs/tags/" ref "^{}" { peeled = $1 }
            END {
                if (head) print head
                else if (peeled) print peeled
                else print tag
            }
        ')"
        if [ -z "$commit" ]; then
            echo "Error: Git returned no commit for '$name' branch/tag '$branch'."
            return 1
        fi
        printf '%s\t%s\t%s\t%s\n' "$name" "$branch" "$commit" "$url" >>"$RELEASE_FILE"
    done < <(jq -c '.[]' "$SCRIPT_DIR/apps.json")
}

print_release_plan() {
    echo "Target site:  $SITE_DOMAIN"
    echo "Image:        $CUSTOM_IMAGE"
    echo "Database:     ${DATABASE_MODE:-local} (${DB_HOST:-db}:${DB_PORT:-3306})"
    echo "Source revisions:"
    awk -F '\t' '{printf "  - %s: %s @ %.12s\n", $1, $2, $3}' "$RELEASE_FILE"
}

preflight() {
    runtime_require_command docker
    runtime_require_command jq
    runtime_require_command git
    runtime_require_command python3
    runtime_require_command base64
    docker info >/dev/null 2>&1 || {
        echo "Error: Docker daemon is unavailable to the current user."
        return 1
    }
    validate_app_configuration
    runtime_validate_compose
    if [ ! -f "$SCRIPT_DIR/frappe_docker/images/custom/Containerfile" ]; then
        echo "Error: frappe_docker build context is missing. Run ./setup.sh for first-time setup."
        return 1
    fi
    runtime_backend_is_running || {
        echo "Error: Backend is not running. Use setup.sh only if this is first setup or reconfiguration."
        return 1
    }
    runtime_site_exists || {
        echo "Error: Site '$SITE_DOMAIN' does not exist. Run ./setup.sh for first-time setup."
        return 1
    }
    runtime_bench_site list-apps >/dev/null
    resolve_source_revisions
    runtime_verify
}

prepare_build_apps_json() {
    BUILD_APPS_JSON="$SCRIPT_DIR/apps.json"
    PRIVATE_APPS_JSON=""

    if ! apps_require_github_token; then
        return
    fi

    PRIVATE_APPS_JSON="$(mktemp)"
    chmod 600 "$PRIVATE_APPS_JSON"
    jq --arg token "$GITHUB_TOKEN" '
        map(
            if .private == true then
                .url = (.url | sub(
                    "^https://github.com/";
                    "https://x-access-token:\($token)@github.com/"
                ))
            else . end
            | del(.private)
        )
    ' "$SCRIPT_DIR/apps.json" >"$PRIVATE_APPS_JSON"
    BUILD_APPS_JSON="$PRIVATE_APPS_JSON"
}

build_candidate_image() {
    local build_status
    local timestamp

    timestamp="$(date +%Y%m%d%H%M%S)"
    CANDIDATE_IMAGE="${CUSTOM_IMAGE}-candidate-${timestamp}"
    prepare_build_apps_json

    echo "Building candidate image: $CANDIDATE_IMAGE"
    set +e
    docker build \
        --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
        --build-arg CACHE_BUST="$(date +%s)" \
        --secret id=apps_json,src="$BUILD_APPS_JSON" \
        --tag "$CANDIDATE_IMAGE" \
        --file "$SCRIPT_DIR/frappe_docker/images/custom/Containerfile" \
        "$SCRIPT_DIR/frappe_docker" 2>&1 | redact_github_token
    build_status=${PIPESTATUS[0]}
    set -e

    if [ -n "$PRIVATE_APPS_JSON" ]; then
        rm -f -- "$PRIVATE_APPS_JSON"
        PRIVATE_APPS_JSON=""
    fi
    if [ "$build_status" -ne 0 ]; then
        echo "Error: Candidate image build failed. Running containers were not changed."
        return "$build_status"
    fi

    if runtime_is_truthy "${S3_STORAGE_ENABLED:-false}" &&
        ! docker run --rm --entrypoint /home/frappe/frappe-bench/env/bin/python \
            "$CANDIDATE_IMAGE" -c 'import boto3' >/dev/null 2>&1; then
        echo "Adding the required boto3 dependency to the candidate image..."
        docker build \
            --build-arg BASE_IMAGE="$CANDIDATE_IMAGE" \
            --tag "$CANDIDATE_IMAGE" \
            --file - "$SCRIPT_DIR" <<'DOCKERFILE'
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
USER frappe
RUN /home/frappe/frappe-bench/env/bin/pip install --no-cache-dir "boto3>=1.34.0"
DOCKERFILE
    fi
}

sync_custom_app_mounts() {
    local branch
    local name
    local row
    local target
    local url

    while IFS= read -r row; do
        name="$(printf '%s' "$row" | jq -r '.name // (.url | split("/") | last | sub("\\.git$"; ""))')"
        url="$(printf '%s' "$row" | jq -r '.url')"
        branch="$(printf '%s' "$row" | jq -r '.branch // "main"')"
        target="$SCRIPT_DIR/frappe_docker/apps/$name"

        if [ ! -d "$target/.git" ]; then
            echo "Cloning custom app mount: $name"
            git_with_github_auth clone --branch "$branch" "$url" "$target"
            continue
        fi

        git -C "$target" remote set-url origin "$url"
        git_with_github_auth -C "$target" fetch origin "$branch"
        git -C "$target" reset --hard FETCH_HEAD
    done < <(jq -c '.[] | select(.is_custom == true)' "$SCRIPT_DIR/apps.json")
}

install_new_apps() {
    local app
    local installed

    installed="$(runtime_bench_site list-apps)"
    while IFS= read -r app; do
        [ -n "$app" ] || continue
        [ "$app" = "frappe" ] && continue
        if [ "$app" = "frappe_s3_attachment" ] &&
            ! runtime_is_truthy "${S3_STORAGE_ENABLED:-false}"; then
            continue
        fi
        if printf '%s\n' "$installed" | awk '{print $1}' | grep -Fxq "$app"; then
            continue
        fi
        echo "Installing newly configured app: $app"
        runtime_bench_site install-app "$app"
    done < <(jq -r '.[] | .name // (.url | split("/") | last | sub("\\.git$"; ""))' "$SCRIPT_DIR/apps.json")
}

write_release_record() {
    local destination="$SCRIPT_DIR/logs/releases"
    local record="$destination/$(date +%Y-%m-%d_%H-%M-%S).txt"

    mkdir -p "$destination"
    {
        echo "site=$SITE_DOMAIN"
        echo "image=$CUSTOM_IMAGE"
        echo "deployed_at=$(date --iso-8601=seconds)"
        echo "sources:"
        awk -F '\t' '{printf "  %s %s %s %s\n", $1, $2, $3, $4}' "$RELEASE_FILE"
    } >"$record"
    echo "Release record: $record"
}

on_exit() {
    local status=$?

    if [ -n "${PRIVATE_APPS_JSON:-}" ]; then
        rm -f -- "$PRIVATE_APPS_JSON"
    fi
    if [ -n "${RELEASE_FILE:-}" ]; then
        rm -f -- "$RELEASE_FILE"
    fi
    if [ "$status" -ne 0 ] && [ "$DEPLOY_ACTIVE" -eq 1 ]; then
        echo "Deployment failed. Site '$SITE_DOMAIN' remains in Maintenance Mode."
        echo "Do not restore the database automatically after a migration failure."
        echo "Inspect: ./ops.sh status and ./ops.sh logs backend"
        echo "After recovery, disable maintenance with: ./ops.sh maintenance-off --yes"
    fi
    script_logging_finish "$status"
    exit "$status"
}

run_apply() {
    local rollback_image="${CUSTOM_IMAGE}-rollback-$(date +%Y%m%d%H%M%S)"

    preflight
    print_release_plan
    echo "This deploy builds a new image, creates a verified backup, runs migrations, and restarts Frappe."
    runtime_confirm DEPLOY "Type DEPLOY to continue: " "$YES"
    runtime_acquire_lock deploy

    # Build first so a source or image failure does not interrupt the running site.
    build_candidate_image

    DEPLOY_ACTIVE=1
    runtime_set_maintenance on
    runtime_stop_writers
    "$SCRIPT_DIR/backup.sh" --yes
    sync_custom_app_mounts

    if docker image inspect "$CUSTOM_IMAGE" >/dev/null 2>&1; then
        docker tag "$CUSTOM_IMAGE" "$rollback_image"
        echo "Previous image retained as: $rollback_image"
    fi
    docker tag "$CANDIDATE_IMAGE" "$CUSTOM_IMAGE"

    # Keep Redis untouched and do not run the first-setup create-site service.
    # The one-shot configurator updates shared site settings before the backend
    # is recreated with the new image.
    runtime_compose run --rm --no-deps configurator
    runtime_compose up -d --no-deps --force-recreate backend
    runtime_wait_for_backend
    install_new_apps
    runtime_bench_site migrate
    runtime_clear_caches
    runtime_compose up -d --no-deps --force-recreate websocket
    runtime_wait_for_service websocket
    runtime_compose up -d --no-deps --force-recreate frontend
    runtime_wait_for_service frontend
    runtime_compose up -d --no-deps --force-recreate queue-long queue-short scheduler
    runtime_verify
    runtime_set_maintenance off
    DEPLOY_ACTIVE=0
    write_release_record
    echo "Deployment completed successfully for site '$SITE_DOMAIN'."
}

main() {
    parse_args "$@"
    runtime_load_configuration "$SCRIPT_DIR"
    : "${FRAPPE_BRANCH:?FRAPPE_BRANCH is required in .env}"
    apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"
    trap on_exit EXIT

    case "$COMMAND" in
        check)
            preflight
            print_release_plan
            echo "Deployment preflight passed."
            ;;
        plan)
            preflight
            print_release_plan
            cat <<'EOF'
Planned actions:
  1. Build and validate a candidate image while the current site is running.
  2. Enable Maintenance Mode and stop scheduler/queue workers.
  3. Create and verify a database/files backup.
  4. Sync custom app mounts and recreate Frappe services.
  5. Install newly configured apps and run bench migrate once.
  6. Clear caches, restart workers, verify, and disable Maintenance Mode.
EOF
            ;;
        apply) run_apply ;;
        verify) runtime_validate_compose; runtime_verify ;;
    esac
}

main "$@"
