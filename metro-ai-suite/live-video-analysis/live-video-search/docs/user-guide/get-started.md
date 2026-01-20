# Live Video Search - Getting Started

## Overview

Live Video Search is a Metro AI Suite sample that **bridges Smart NVR ingestion with VSS Search**. It captures live events from cameras, writes clips to a shared dump directory, and makes them searchable via natural‑language queries and time‑range filters. This guide starts the **Live Video Search** stack (Smart NVR + VSS Search) using Docker Compose.

## Prerequisites

- Verify that your system meets the [minimum requirements](./system-requirements.md).
- Install Docker tool: [Installation Guide](https://docs.docker.com/get-docker/).
- Install Docker Compose tool: [Installation Guide](https://docs.docker.com/compose/install/).

## Project Structure

```text
live-video-search/
├── config/                        # Local configuration and assets
│   ├── frigate-config/            # Frigate camera configs (active + templates)
│   ├── mqtt-config/               # Mosquitto configuration
│   ├── telemetry/                 # Telemetry collector configs
│   └── nginx.conf                 # NGINX reverse proxy
├── data/                           # Runtime data (recordings, caches)
│   └── live-recordings/           # Shared recordings directory
├── docker/                         # Compose files
│   ├── compose.search.yaml        # VSS Search stack
│   ├── compose.smart-nvr.yaml      # Smart NVR stack
│   └── compose.telemetry.yaml      # Telemetry collector
├── docs/                           # Documentation
│   └── user-guide/                # User guides
├── setup.sh                        # Main setup script
└── README.md                       # Project overview
```

## Set Required Environment Variables

Before running the application, you need to set several environment variables:

1. **Configure the registry**:
   The application uses registry URL and tag to pull the required images.

    ```bash
    export REGISTRY_URL=intel
    export TAG=1.3.1
    ```

2. **Set required credentials for some services**:
   Following variables **MUST** be set on your current shell before running the setup script:

    ```bash
    # MinIO credentials (object storage)
    export MINIO_ROOT_USER=<minio-user>
    export MINIO_ROOT_PASSWORD=<minio-pass>

    # PostgreSQL credentials (database)
    export POSTGRES_USER=<postgres-user>
    export POSTGRES_PASSWORD=<postgres-pass>

    # Embedding model for search
    export EMBEDDING_MODEL_NAME="CLIP/clip-vit-b-32"

    # MQTT credentials (Smart NVR)
    export MQTT_USER=<mqtt-user>
    export MQTT_PASSWORD=<mqtt-pass>
    ```

## Optional Environment Variables

You can customize the application behavior by setting the following optional environment variables before running the setup script:

1. **Configure directory shared by Smart NVR and VSS watcher**:

    By default, Smart NVR writes recorded clips to `live-video-search/data/live-recordings/`, which is also monitored by the VSS Search‑MS watcher for new content. To change this path, set the `LIVE_VIDEO_DUMP_DIR` environment variable before running the setup script:

    ```bash
    # Override live recordings directory shared by Smart NVR and VSS watcher
    export LIVE_VIDEO_DUMP_DIR=/path/to/live/recordings
    ```

2. **Control the frame extraction interval (Video Search Mode)**:

    The DataPrep microservice samples frames from uploaded videos according to the `FRAME_INTERVAL` environment variable. Set this variable before running `source setup.sh --search` to control how often frames are selected for processing.

    ```bash
    export FRAME_INTERVAL=15
    ```

    In the example above, DataPrep processes every fifteenth frame: each selected frame (optionally after object detection) is converted into embeddings and stored in the vector database. Lower values improve recall at the cost of higher compute and storage usage, while higher values reduce processing load but may skip important frames. If you do not set this variable, the service falls back to its configured default.

3. To use GPU acceleration for embedding generation, set the following variable before running the setup script:

    ```bash
    # Enable GPU embeddings
    export ENABLE_EMBEDDING_GPU=true
    ```

4. **Toggle GenAI features in Smart NVR**:
    By default, GenAI features in Smart NVR are disabled. To enable them, set the following environment variables before running the setup script:

    ```bash
    # Enable GenAI features in Smart NVR
    export NVR_GENAI=false
    export NVR_SCENESCAPE=false
    ```




## Configure Cameras

Edit `config/frigate-config/config.yml` to add or update camera inputs. This is the active Frigate configuration used at startup.

For reference, see the default template in `config/frigate-config/config-default.yml`.

## Start the Application

```bash
source setup.sh --start
```

Access:

- VSS UI: `http://<host-ip>:12345`
- Smart NVR UI: `http://<host-ip>:7860`

## How to Use Live Video Search

This workflow assumes the stack is running and cameras are configured in Frigate.

### Step 1: Validate Ingestion

1. Open Smart NVR UI at `http://<host-ip>:7860`.
2. Confirm camera streams are live and clips are being recorded.
3. Verify the shared recordings directory contains new clips:
    - Default: `live-video-search/data/live-recordings/`

### Step 2: Run a Search Query

1. Open VSS UI at `http://<host-ip>:12345`.
2. Select one or more cameras.
3. Set a **time range** using either:
    - **UI time range picker**, or
    - **Natural‑language query** (examples below).
4. Enter a query and run search.

#### Example Queries (Time Range Parsing)

- `person seen in last 5 minutes`
- `car near garage in the past hour`
- `delivery truck last 30 minutes`

### Step 3: Review Results

Search results include clip timestamps, confidence scores, and metadata. Use the playback controls to jump to the exact event.

### Tips

- If results are empty, confirm new clips exist in the shared recordings path.
- Narrow time ranges improve query latency and relevance.
- If telemetry is not visible, check that `vss-collector` is running.

## Stop or Reset

```bash
# Stop all containers
source setup.sh --down

# Remove volumes and live recordings
source setup.sh --clean-data
```

## Telemetry

Telemetry is enabled for Live Video Search and shows live system metrics in the VSS UI when the collector is connected.


## Troubleshooting

### No clips in search results

- Confirm Smart NVR is writing to the shared dump directory.
- Check `LIVE_VIDEO_DUMP_DIR` is the same for Frigate and Search‑MS watcher.
- Verify new files exist under `data/live-recordings/`.

### Search results empty after changing model

- If you changed `EMBEDDING_MODEL_NAME`, clean data and re‑ingest:
  - `source setup.sh --clean-data`
  - `source setup.sh --start`

### Telemetry not showing

- Verify `vss-collector` is running.
- Check Pipeline Manager status: `/manager/metrics/status`.

### MQTT connection errors

- Ensure `MQTT_USER` and `MQTT_PASSWORD` are set.
- Confirm `mqtt-broker` is healthy: `docker ps` and `docker logs mqtt-broker`.

### Stream disconnects

- Check Frigate logs for camera connection errors.
- Confirm RTSP sources are reachable and credentials are valid.

### Permission errors on recordings

- If Search‑MS cannot delete files, ensure the recordings directory is writable by the container.
- Remove and recreate recordings directory after switching user mode.

## References

- [Smart NVR docs](../../../../smart-nvr/docs/user-guide/get-started.md)
- [VSS API (public)](https://github.com/open-edge-platform/edge-ai-libraries/tree/main/sample-applications/video-search-and-summarization/docs/user-guide)
