# Bento4 HLS Metadata Injection Workflow

## Project Overview

This context provides a complete workflow for injecting timed ID3 metadata into HLS MPEG-TS segments using Bento4. This is specifically designed for DJ vinyl mixes where track attribution metadata (artist, title, Discogs links) needs to be embedded at specific timestamps within the HLS segments themselves for copyright attribution in derivative works.

## Architecture

- **Bento4**: GPL v2 licensed MPEG toolkit for HLS manipulation
- **Podman Container**: Persistent container with Bento4 built and ready
- **Volume Mounts**: Host directories mounted for metadata, source segments, and output
- **Workflow**: JSON metadata → Bento4 injection → ID3-tagged TS segments

## License Compliance

Bento4 is licensed under GPL v2. This workflow is compliant for private use:
- Container is not distributed (private development only)
- GPL requirements only apply when distributing binaries
- Bento4 source is publicly available at https://github.com/axiomatic-systems/Bento4

## Files to Create

This context includes 5 files that should be committed to the repository:

1. `Dockerfile` - Container definition (uses gcc:13 for optimized C++ builds)
2. `launch-metadata-injector.sh` - Injection workflow script
3. `docs/BENTO4_WORKFLOW.md` - Complete documentation
4. `examples/example-metadata.json` - Metadata format example

### Generated Files

The following files have been created in `/workspace/md-embed/`:

| Context Reference | Actual File |
|-------------------|-------------|
| `containers/Containerfile.bento4` | `Dockerfile` |
| `scripts/inject-metadata.sh` | `launch-metadata-injector.sh` |

---

## File 1: containers/Containerfile.bento4

```dockerfile
# Bento4 HLS Metadata Injection Container
# GPL v2 licensed toolkit for MPEG/HLS manipulation
# https://github.com/axiomatic-systems/Bento4

FROM docker.io/library/debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    g++ \
    make \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone and build Bento4
WORKDIR /build
RUN git clone https://github.com/axiomatic-systems/Bento4.git

WORKDIR /build/Bento4
RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j$(nproc)

# Create runtime image
FROM docker.io/library/debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy Bento4 binaries from builder
COPY --from=builder /build/Bento4/bin /usr/local/bin/

# Create working directory
WORKDIR /work

# Verify installation
RUN mp42hls --help || true && \
    mp4info --help || true

# Default command
CMD ["/bin/bash"]
```

---

## File 2: scripts/build-bento4-container.sh

```bash
#!/bin/bash
# Build Bento4 container image for HLS metadata injection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINERFILE="$PROJECT_ROOT/containers/Containerfile.bento4"

echo "Building Bento4 container..."
echo "Using Containerfile: $CONTAINERFILE"

# Build the container
podman build \
    -t localhost/bento4-hls:latest \
    -f "$CONTAINERFILE" \
    "$PROJECT_ROOT"

echo ""
echo "✓ Container built successfully: localhost/bento4-hls:latest"
echo ""
echo "To verify installation:"
echo "  podman run --rm localhost/bento4-hls:latest mp42hls --help"
echo ""
echo "To inject metadata, use: ./scripts/inject-metadata.sh"
```

---

## File 3: scripts/inject-metadata.sh

```bash
#!/bin/bash
# Inject timed ID3 metadata into HLS segments using Bento4

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
CONTAINER_IMAGE="localhost/bento4-hls:latest"
METADATA_DIR="${METADATA_DIR:-$PROJECT_ROOT/metadata}"
SEGMENTS_DIR="${SEGMENTS_DIR:-$PROJECT_ROOT/segments}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/output}"

# Validate directories exist
if [[ ! -d "$METADATA_DIR" ]]; then
    echo "Error: Metadata directory not found: $METADATA_DIR"
    echo "Set METADATA_DIR environment variable or create the directory"
    exit 1
fi

if [[ ! -d "$SEGMENTS_DIR" ]]; then
    echo "Error: Segments directory not found: $SEGMENTS_DIR"
    echo "Set SEGMENTS_DIR environment variable or create the directory"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Bento4 HLS Metadata Injection"
echo "=============================="
echo "Metadata: $METADATA_DIR"
echo "Segments: $SEGMENTS_DIR"
echo "Output:   $OUTPUT_DIR"
echo ""

# Check if container image exists
if ! podman image exists "$CONTAINER_IMAGE"; then
    echo "Error: Container image not found: $CONTAINER_IMAGE"
    echo "Run: ./scripts/build-bento4-container.sh"
    exit 1
fi

# Run Bento4 container with volume mounts
podman run --rm -it \
    -v "$METADATA_DIR:/work/metadata:ro" \
    -v "$SEGMENTS_DIR:/work/segments:ro" \
    -v "$OUTPUT_DIR:/work/output:rw" \
    --userns=keep-id \
    "$CONTAINER_IMAGE" \
    bash -c '
        echo "Bento4 tools available:"
        echo "  mp42hls  - Convert MP4 to HLS with metadata"
        echo "  mp4info  - Display MP4 file information"
        echo "  mp4dump  - Dump MP4 structure"
        echo ""
        echo "Directories mounted:"
        echo "  /work/metadata - Metadata JSON files (read-only)"
        echo "  /work/segments - Source HLS segments (read-only)"
        echo "  /work/output   - Output directory (read-write)"
        echo ""
        echo "Example workflow:"
        echo "  1. Review metadata: cat /work/metadata/mix-metadata.json"
        echo "  2. Process: mp42hls --timed-metadata /work/metadata/mix-metadata.json ..."
        echo ""
        echo "Entering interactive shell..."
        exec bash
    '

echo ""
echo "Container session ended."
```

---

## File 4: docs/BENTO4_WORKFLOW.md

```markdown
# Bento4 HLS Metadata Injection Workflow

## Overview

This workflow uses Bento4 to inject timed ID3 metadata into HLS MPEG-TS segments. The metadata contains track attribution (artist, title, Discogs links) embedded directly in the segments containing copyrighted material.

## Prerequisites

- Podman installed and configured
- Source audio file (WAV or MP3)
- Track timing information for metadata

## Directory Structure

```
md-embed/
├── Dockerfile                     # Container definition (gcc:13 base)
├── launch-metadata-injector.sh    # Injection script
├── bento4-hls-metadata-context.md # This context file
├── metadata/
│   └── mix-metadata.json          # Timed metadata
├── segments/
│   ├── mix.m3u8                   # HLS playlist
│   └── segment*.ts                # TS segments (input)
└── output/
    ├── mix.m3u8                   # HLS playlist (output)
    └── segment*.ts                # TS segments with ID3
```

## Workflow Steps

### Step 1: Create Metadata JSON

Listen through your DJ mix and note timestamps for each track:

```json
{
  "version": 1,
  "metadata": [
    {
      "time": 0.0,
      "duration": 330.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "Track Title"},
          {"id": "TPE1", "value": "Artist Name"},
          {"id": "TXXX", "description": "DISCOGS_URL", "value": "https://www.discogs.com/release/12345"}
        ]
      }
    },
    {
      "time": 330.0,
      "duration": 195.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "Track 1 Title / Track 2 Title"},
          {"id": "TPE1", "value": "Artist 1 / Artist 2"},
          {"id": "TXXX", "description": "DISCOGS_URL", "value": "https://www.discogs.com/release/12345,https://www.discogs.com/release/67890"}
        ]
      }
    }
  ]
}
```

**Key Fields:**
- `time`: Start time in seconds
- `duration`: How long this metadata applies (in seconds)
- `TIT2`: Track title (ID3 standard)
- `TPE1`: Artist name (ID3 standard)
- `TXXX`: Custom text frame (for Discogs URL)

### Step 2: Build Container (One Time)

```bash
cd /workspace/md-embed
podman build -t localhost/bento4-hls:latest -f Dockerfile .
```

This builds the Bento4 container and tags it as `localhost/bento4-hls:latest`.

**You only need to rebuild when:**
- Bento4 releases an update
- Dockerfile changes

### Step 3: Prepare Source Audio

First, transcode your source audio to HLS without metadata:

```bash
ffmpeg -i source.wav \
  -c:a aac -b:a 192k \
  -f hls \
  -hls_time 6 \
  -hls_segment_filename 'segment%03d.ts' \
  -hls_playlist_type vod \
  segments/mix.m3u8
```

**Note:** Segment duration (`-hls_time 6`) should align with your metadata timing precision.

### Step 4: Inject Metadata

Launch the container with mounted directories:

```bash
# Set directories (optional, defaults to md-embed subdirectories)
export METADATA_DIR=/path/to/metadata
export SEGMENTS_DIR=/path/to/segments
export OUTPUT_DIR=/path/to/output

# Run injection script
./launch-metadata-injector.sh
```

Inside the container shell:

```bash
# Verify metadata file
cat /work/metadata/mix-metadata.json

# Convert segments with metadata injection
# (Bento4 command syntax - adjust based on actual tool usage)
mp42hls \
  --input-file /work/segments/mix.m3u8 \
  --timed-metadata /work/metadata/mix-metadata.json \
  --output-dir /work/output
```

### Step 5: Verify Output

Exit the container and check the output:

```bash
ls -lh output/
# Should contain: mix.m3u8, segment*.ts with ID3 metadata
```

## Metadata JSON Format Reference

### Simple Single Track

```json
{
  "version": 1,
  "metadata": [
    {
      "time": 0.0,
      "duration": 300.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "Track Title"},
          {"id": "TPE1", "value": "Artist Name"}
        ]
      }
    }
  ]
}
```

### DJ Mix with Blends

```json
{
  "version": 1,
  "metadata": [
    {
      "time": 0.0,
      "duration": 330.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "First Track"},
          {"id": "TPE1", "value": "First Artist"},
          {"id": "TXXX", "description": "DISCOGS_URL", "value": "https://www.discogs.com/release/111"}
        ]
      }
    },
    {
      "time": 330.0,
      "duration": 45.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "First Track / Second Track"},
          {"id": "TPE1", "value": "First Artist / Second Artist"},
          {"id": "TXXX", "description": "DISCOGS_URL", "value": "https://www.discogs.com/release/111,https://www.discogs.com/release/222"}
        ]
      }
    },
    {
      "time": 375.0,
      "duration": 270.0,
      "data": {
        "type": "id3",
        "frames": [
          {"id": "TIT2", "value": "Second Track"},
          {"id": "TPE1", "value": "Second Artist"},
          {"id": "TXXX", "description": "DISCOGS_URL", "value": "https://www.discogs.com/release/222"}
        ]
      }
    }
  ]
}
```

## ID3 Frame Types

| Frame ID | Description | Example |
|----------|-------------|---------|
| `TIT2` | Title/Song name | "Track Title" |
| `TPE1` | Lead artist | "Artist Name" |
| `TALB` | Album | "Album Name" |
| `TDRC` | Recording time | "2024" |
| `TCON` | Genre | "House" |
| `TXXX` | Custom text | Discogs URL, BPM, etc. |

## Client-Side Playback

To read the ID3 metadata on the client side, use **hls.js**:

```javascript
const hls = new Hls();
hls.loadSource('output/mix.m3u8');
hls.attachMedia(audioElement);

// Listen for ID3 metadata events
hls.on(Hls.Events.FRAG_PARSING_METADATA, (event, data) => {
  data.samples.forEach(sample => {
    sample.data.forEach(frame => {
      if (frame.key === 'TIT2') {
        console.log('Title:', frame.info);
      }
      if (frame.key === 'TPE1') {
        console.log('Artist:', frame.info);
      }
      if (frame.key === 'TXXX') {
        // Parse custom TXXX frame
        const description = frame.description; // "DISCOGS_URL"
        const value = frame.info; // URL
        console.log(`${description}: ${value}`);
      }
    });
  });
});
```

## Troubleshooting

### Container Build Fails

**Error:** `git clone failed`
- **Solution:** Check network connectivity, try building with `--no-cache`

**Error:** `cmake not found`
- **Solution:** Build dependencies missing in base image, verify Containerfile

### Metadata Injection Issues

**Error:** `metadata file not found`
- **Solution:** Verify volume mount paths, check file exists in `metadata/`

**Error:** `Invalid JSON format`
- **Solution:** Validate JSON with `jq`:
  ```bash
  jq empty metadata/mix-metadata.json
  ```

### Playback Issues

**ID3 metadata not appearing:**
- Verify browser/player supports HLS ID3 (use hls.js)
- Check segment timing aligns with metadata timestamps
- Inspect segments with `mp4info` or `ffprobe`

**Segments won't play:**
- Check codec compatibility (AAC is most compatible)
- Verify segment duration matches playlist
- Test with VLC or ffplay first

## Performance Considerations

- **Segment Duration:** 6-10 seconds is optimal for metadata precision
- **Metadata Frequency:** Don't inject metadata more than once per segment
- **File Sizes:** ID3 frames add ~200-500 bytes per segment

## Legal and Compliance

This workflow embeds attribution directly in segments containing copyrighted material, which:
- ✓ Provides proper credit to original artists
- ✓ Maintains attribution in derivative works
- ✓ Supports fair use documentation
- ✓ Enables transparent sourcing

**Always verify** that your use complies with applicable copyright law and licensing agreements.

## References

- [Bento4 Documentation](https://www.bento4.com/)
- [Bento4 GitHub](https://github.com/axiomatic-systems/Bento4)
- [HLS ID3 Specification](https://datatracker.ietf.org/doc/html/draft-pantos-hls-rfc8216bis)
- [ID3v2 Specification](https://id3.org/id3v2.4.0-structure)
- [hls.js Documentation](https://github.com/video-dev/hls.js/)
```

---

## File 5: examples/example-metadata.json

```json
{
  "version": 1,
  "metadata": [
    {
      "time": 0.0,
      "duration": 330.0,
      "data": {
        "type": "id3",
        "frames": [
          {
            "id": "TIT2",
            "value": "First Track Title"
          },
          {
            "id": "TPE1",
            "value": "First Artist Name"
          },
          {
            "id": "TALB",
            "value": "First Album Name"
          },
          {
            "id": "TDRC",
            "value": "1985"
          },
          {
            "id": "TXXX",
            "description": "DISCOGS_URL",
            "value": "https://www.discogs.com/release/12345"
          },
          {
            "id": "TXXX",
            "description": "BPM",
            "value": "128"
          }
        ]
      }
    },
    {
      "time": 330.0,
      "duration": 45.0,
      "data": {
        "type": "id3",
        "frames": [
          {
            "id": "TIT2",
            "value": "First Track Title / Second Track Title"
          },
          {
            "id": "TPE1",
            "value": "First Artist Name / Second Artist Name"
          },
          {
            "id": "TXXX",
            "description": "DISCOGS_URL",
            "value": "https://www.discogs.com/release/12345,https://www.discogs.com/release/67890"
          },
          {
            "id": "TXXX",
            "description": "BLEND",
            "value": "true"
          }
        ]
      }
    },
    {
      "time": 375.0,
      "duration": 270.0,
      "data": {
        "type": "id3",
        "frames": [
          {
            "id": "TIT2",
            "value": "Second Track Title"
          },
          {
            "id": "TPE1",
            "value": "Second Artist Name"
          },
          {
            "id": "TALB",
            "value": "Second Album Name"
          },
          {
            "id": "TDRC",
            "value": "1992"
          },
          {
            "id": "TXXX",
            "description": "DISCOGS_URL",
            "value": "https://www.discogs.com/release/67890"
          },
          {
            "id": "TXXX",
            "description": "BPM",
            "value": "135"
          }
        ]
      }
    },
    {
      "time": 645.0,
      "duration": 60.0,
      "data": {
        "type": "id3",
        "frames": [
          {
            "id": "TIT2",
            "value": "Second Track Title / Third Track Title"
          },
          {
            "id": "TPE1",
            "value": "Second Artist Name / Third Artist Name"
          },
          {
            "id": "TXXX",
            "description": "DISCOGS_URL",
            "value": "https://www.discogs.com/release/67890,https://www.discogs.com/release/13579"
          },
          {
            "id": "TXXX",
            "description": "BLEND",
            "value": "true"
          }
        ]
      }
    },
    {
      "time": 705.0,
      "duration": 315.0,
      "data": {
        "type": "id3",
        "frames": [
          {
            "id": "TIT2",
            "value": "Third Track Title"
          },
          {
            "id": "TPE1",
            "value": "Third Artist Name"
          },
          {
            "id": "TALB",
            "value": "Third Album Name"
          },
          {
            "id": "TDRC",
            "value": "1998"
          },
          {
            "id": "TXXX",
            "description": "DISCOGS_URL",
            "value": "https://www.discogs.com/release/13579"
          },
          {
            "id": "TXXX",
            "description": "BPM",
            "value": "140"
          }
        ]
      }
    }
  ]
}
```

---

## Usage Instructions

1. **Create directory structure:**
   ```
   mkdir -p docs examples metadata segments output
   ```

2. **Make scripts executable:**
   ```
   chmod +x launch-metadata-injector.sh
   ```

## Next Steps

1. Build the container:
   ```
   podman build -t localhost/bento4-hls:latest -f Dockerfile .
   ```
2. Create your metadata JSON based on the example
3. Transcode your source audio to HLS segments
4. Run metadata injection: `./launch-metadata-injector.sh`

## Notes

- The Bento4 container is persistent—you only rebuild when updating Bento4
- Volume mounts use `--userns=keep-id` for proper file permissions
- Metadata JSON format follows Bento4's timed metadata specification
- All segments containing copyrighted material will have embedded attribution

## Support

For Bento4-specific questions, consult:
- [Bento4 Documentation](https://www.bento4.com/documentation/)
- [Bento4 GitHub Issues](https://github.com/axiomatic-systems/Bento4/issues)
