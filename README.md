# Camden Wander portfolio-site

Static HTML5 portfolio site for live techno artist Camden Wander, featuring HLS (HTTP Live Streaming) audio playback with an interactive track timeline feature supporting fast-forward and reverse cueing.

## Architecture

The site runs without build tools, bundlers, or package managers. HLS.js loads from CDN.

```
site-root/
├── index.html
├── css/camden-wander.css
├── img/                         # image media for the site
├── js/
│   └── camden-wander.js        # HLS player, track lists, audio analysis
└── hls/
    └── {track-name}/           # "Movements" and performance recording available for playback
        ├── master.m3u8         # Adaptive bitrate playlist
        ├── 64k/stream.m3u8     # Low bandwidth tier
        ├── 128k/stream.m3u8    # Medium bandwidth tier
        └── 192k/stream.m3u8    # High bandwidth tier
```

## Development Container

The development environment runs in a Podman container with the Apache httpd:2.4-alpine image as the base image. The `dev-server/httpd.conf` file is copied to the `/usr/local/apache2/htdocs` container directory, and `site-root/` is volume mounted within the container's `/usr/local/apache2/htdocs/` directory.

```bash
## !! changes to dev-server/httpd.conf require `--force-rebuild` ##
./dev-server/launch-server.sh (--force-rebuild)
```

The container:
- Serves the site on port 8080

## Publishing

Prototype deploys `site-root/` to Linode Object Storage via s3cmd.

```bash
./publish/launch-deploy-container.sh
```

Requires s3cmd configuration at ~/.s3cfg on the host. The container mounts this config read-only and syncs site-root to the configured bucket with public-read ACL.

## External Dependencies

- HLS.js (CDN) - Adaptive bitrate streaming, Apache License 2.0
- Google Fonts - Orbitron (titles), Rubik (body)

## Contributing

This repository is a creative and technical portfolio for Noise2Signal LLC. While the interest is appreciated, this project is not accepting external contributions. The Issues list provides visibility to the author's task tracking before publication.

## Container Requirements

All workflows use Podman. Each container:
- Builds from a Containerfile in its directory
- Supports --force-rebuild flag to recreate the image

No Docker daemon required. Containers are rootless and run under the invoking user's namespace.
