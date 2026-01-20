# Live Video Search

Live Video Search is a Metro AI Suite sample that **bridges Smart NVR ingestion with VSS Search**. It captures live events from cameras, writes clips to a shared dump directory, and makes them searchable via natural‑language queries and time‑range filters.

## Documentation

- **Overview**
  - [Overview](docs/user-guide/index.md): High‑level introduction and navigation.
  - [Architecture](docs/user-guide/overview-architecture-live-video-search.md): End‑to‑end architecture.

- **Getting Started**
  - [Get Started](docs/user-guide/get-started.md): Step‑by‑step setup.
  - [System Requirements](docs/user-guide/system-requirements.md): Hardware and software requirements.
  - [How to Use the Application](docs/user-guide/how-to-use-application.md): Search workflow and tips.

- **Deployment**
  - [Build from Source](docs/user-guide/how-to-build-from-source.md): Build images for the stack.

- **API Reference**
  - [API Reference](docs/user-guide/api-reference.md): Key endpoints and references.

- **Release Notes**
  - [Release Notes](docs/user-guide/release-notes.md): Updates and fixes.

## Notes

- Telemetry is **enabled** for this app and shown in the VSS UI when connected.
- Smart NVR writes clips to a shared dump directory used by the VSS watcher.
