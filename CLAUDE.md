# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Container Environment

Claude Code runs inside a container. The /workspace/ directory is a host directory mounted into the container. Git operations (commit, push, pull, branch management) are performed by the user on the container host, not by Claude. Do not execute git commands; file changes made in /workspace/ will be visible to the host user for version control.

### Claude Code Container Launcher

A generalized Claude Code container is defined in another repository.

The launcher:
- Prompts for a host directory to mount as `/workspace` (supports tab-completion)
- Generates a unique container name based on the workspace path
- Allows multiple container instances for different projects simultaneously
- Container name format: `claude-code-{dirname}-{hash}`

This allows working on multiple projects in separate container sessions.

## Container Standards

**Portfolio Site Containers:**
- **Development Server:** Apache httpd (Alpine-based, serves site-root on port 8080)
- **Deployment:** Debian slim with s3cmd (publishes to Linode Object Storage)

## Project Overview

Static HTML5 portfolio site for electronic music artist Camden Wander, featuring live performances of original compositions created with Eurorack modular synthesizers and other hardware instruments. HLS (HTTP Live Streaming) audio playback facilitated with HLS.js loaded from CDN.

**Site Purpose:** Demonstrate ability to provide live performances of electronic music with hardware synthesizers as entertainment.

## Development Server

The portfolio site uses an Apache httpd container for local development:

```bash
# Start development server
./site-root/dev-server/launch-server.sh

# Force rebuild container if needed, for example when dev-server/httpd.conf is updated
./site-root/dev-server/launch-server.sh --force-rebuild

# Stop server
podman stop portfolio-site-dev-server

# Remove container
podman rm portfolio-site-dev-server
```

The server mounts `site-root/` to `/usr/local/apache2/htdocs/synth-performance` and serves on port 8080.

## Architecture

```
site-root/
├── index.html                   # Home page
├── nope.html                    # 404 error page (s3cmd ws-create)
├── css/camden-wander.css
├── js/camden-wander.js          # HLS player, track lists from JSON, info panel toggle
├── img/                         # Images
└── hls/
    └── {track_name}/master.m3u8 # HLS trancoded audio manifests and ts segments at 3 bit rates
```

**Key Flow:** `index.html` loads HLS.js from CDN and contains static track listings. `camden-wander.js` handles info panel toggles, HLS playback, and timeline updates.

**Static Architecture:** Track listings are written directly in `index.html` as `<li>` elements. JavaScript attaches event listeners to these static elements for interactivity. Track metadata in `tracks.json` is reference data only.

**Cache Busting:** `index.html` contains `CACHE_VERSION` placeholders in CSS and JS URLs (`?v=CACHE_VERSION`). The deployment script replaces these with Unix timestamps to force browser cache invalidation.

**404 Page:** `nope.html` serves as the 404 error page, configured via `s3cmd ws-create` when setting up the S3 bucket for static website hosting.

## Publishing

Deploys site-root to Linode Object Storage via s3cmd.

```
publish/
├── Containerfile               # Debian + ca-certificates + s3cmd, developer user
├── bucket-policy.json          # Public read policy for bucket
├── deploy.sh                   # s3cmd sync with exclusions
└── launch-deploy-container.sh  # Mounts ~/.s3cfg
```

**Deployment:**
```bash
./publish/launch-deploy-container.sh
```

The deployment script (`deploy.sh`) performs multiple operations:
1. Generates cache-busting version (Unix timestamp)
2. Injects version into `index.html` (replaces `CACHE_VERSION` placeholder)
3. Applies `bucket-policy.json` to grant public read access to all objects
4. Syncs files by type with explicit MIME types:
   - `*.css` → `text/css`
   - `*.js` → `application/javascript`
   - `*.html` → `text/html`
   - `*.json` → `application/json`
   - `*.m3u8` → `application/vnd.apple.mpegurl` (HLS playlists)
   - `*.ts` → `video/mp2t` (HLS segments)
   - Other files → auto-detected via `--guess-mime-type`
5. Restores `CACHE_VERSION` placeholder in `index.html` (keeps git repo clean)
6. All syncs use `--delete-removed` to remove files from S3 that were deleted locally
7. Excludes `*.md` markdown files from deployment

**Cache Busting:** CSS and JS files are loaded with `?v=CACHE_VERSION` query strings in `index.html`. During deployment, the placeholder is replaced with the current Unix timestamp, forcing browsers to reload updated assets. The placeholder is restored after deployment to avoid git repository changes.

**Bucket Policy:** The `bucket-policy.json` defines a public read policy allowing anonymous access to all objects in the bucket (required for static website hosting).

**Initial Setup:**
The S3 bucket is configured for static website hosting using `s3cmd ws-create`:
```bash
s3cmd ws-create --ws-index=index.html --ws-error=nope.html s3://camden-wander/
```

## External Dependencies

- HLS.js (CDN): `//cdn.jsdelivr.net/npm/hls.js` - adaptive bitrate streaming
- Google Fonts: Orbitron (titles, section headers, player controls), Rubik (track titles, info panels, body text)

## Code Style

- Minimal comments; code should be self-documenting
- Comment only for intent or readable explanation of abstract operations (regex, jq filters)
- Shell scripts output tool stdout only; no echo instrumentation unless tool provides no output (e.g., sed)

## 2026-01-13: Refactor - HLS Path Updates and Apache License Compliance

**[COMPLETED - REFACTOR]:**
- Updated performance track `data-src` paths in `index.html` to match new transcoder output structure:
  - `hls/three-wave-music-december-2024/` → `hls/december-2024/`
  - `hls/modstock-july-2025/` → `hls/july-2025/`
- Removed `site-root/data/tracks.json` and empty `data/` directory
  - JavaScript already uses DOM-based track data (`data-src`, `data-id`, `.track-name` text)
  - No runtime dependency on tracks.json existed
- Current state: Track metadata remains in HTML as static content

**[COMPLETED - AMEND]:**
- Added Apache License 2.0 attribution for hls.js to footer in `index.html` (low-profile span format)
  - Acknowledges Dailymotion (2017) and Brightcove (2013-2015) copyright holders
  - Links to hls.js GitHub repository
- Created `/workspace/NOTICE` file documenting Apache-licensed dependencies
- Updated README:
  - Added "Contributing" section stating repository doesn't accept external contributions
  - Noted HLS.js dependency uses Apache License 2.0

**[DESIRED END STATE - DEFERRED]:**
Metadata extraction from HLS manifest tags for dynamic track display is deferred pending transcoder updates:
- Goal: Extract track title/metadata from HLS manifest tags (e.g., `#EXTINF` title field, custom `#EXT-X-*` tags) via HLS.js parsed manifest data
- Responsibility: Ensuring HLS manifests contain accurate metadata is external to this repository and handled in the `batch-ffmpeg-hls-transcoder` project
- Next step: Once transcoder injects metadata into HLS manifests, implement JavaScript to read parsed manifest data from HLS.js API (e.g., `hls.levels`, `MANIFEST_PARSED` event)
- Vision: Decouple player/timeline into reusable library where HLS manifests are source of truth for track state
