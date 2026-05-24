# Neural-Geolocated Disaster Splatting (3D Flutter Mobile Client)

This is the production-ready front-end repository for the **Neural-Geolocated Disaster Splatting** mobile and desktop client. Built using **Flutter** and **Dart**, this spatial intelligence client communicates with a geolocated backend to ingest smartphone/drone video clips, monitor async Celery reconstruction pipelines, and stream/calibrate 3D Gaussian Splats directly on a responsive 3D WebGL canvas.

---

## 🎨 Visual Identity & Key Visuals

The client is designed with a premium, state-of-the-art visual style tailored for emergency responders and geospatial scientists:
- **Harmony Dark Theme**: Rich space background gradient (`#0A0C16` to `#121424`) with glassmorphic overlay sheets and glowing neon borders.
- **Color-Coded Severities**: Immediate visual assessment via indicator pins (Low: Emerald, Medium: Blue, High: Amber, Critical: Crimson).
- **Responsive 3D Canvas**: 60fps interactive touch orbit controls for panning, zooming, and rotating massive 3D models.

---

## 🏗️ Project Architecture & Layout

The Dart codebase follows high-fidelity SOLID and modular architecture principles:

```
lib/
├── models/
│   ├── splat_capture.dart         # Safe JSON decoders mapping to SQLAlchemy DB schema
│   └── processing_job.dart        # Real-time state mapping to Celery worker responses
├── services/
│   └── api_service.dart           # Multipart REST Client with dynamic Host Server address
├── widgets/
│   ├── glassmorphic_card.dart     # Double-layered BackdropFilter glowing panel containers
│   └── status_badge.dart          # Severity & queue status tags with harmonized color bounds
├── screens/
│   ├── dashboard_screen.dart      # Stat counters panel & quick navigators
│   ├── map_screen.dart            # Dark cartography map with search center & circles
│   ├── upload_screen.dart         # Dual-mode (Video upload vs direct PLY/SPLAT) form + GPS autofill
│   ├── jobs_screen.dart           # Celery async worker queue progress tracker (polling details)
│   ├── viewer_screen.dart         # Embedded high-performance WebView splat renderer
│   └── library_screen.dart        # Searchable inventory browser with quick deletion hooks
└── main.dart                      # App bootstrap, dark styling definitions, and route loading
assets/
└── viewer/
    └── index.html                 # Embedded pure WebGL 3D Gaussian Splat engine (Antimatter15)
```

---

## 🚀 Key Screen Workflows

### 1. 📊 Central Dashboard Hub
- Glowing stats indicators monitoring total captures, active splats, pending Celery builds, and failed logs.
- Quick navigation cards triggering sub-systems.
- **Dynamic Host Settings**: Tap the cog icon to change the API server IP (e.g. `http://192.168.1.50:8000`) on the fly, allowing offline field deployments!

### 2. 🗺️ Interactive Geospatial Radar Map
- Renders detailed cartographic grids under a deep dark aesthetic using CartoDB Dark Matter tiles.
- Double-tap or tap anywhere on the map to position an Indigo search center pin.
- Adjust search radius dynamically using a top glassmorphic slider (1 km to 100 km).
- Displays search circle overlays and pulls georeferenced models dynamically.
- Tapping a pin opens a detailed bottom sheet with elevation tags and orientation matrices.

### 3. 🎥 Video Upload & Direct Splat Ingest
- **Stage 2 Video Reconstruction Form**: Choose title, disaster type, severity, and select an MP4/MOV clip. Tap **GET GPS** to pull high-precision coordinates directly from your device's physical GPS sensors. Pushing the file uploads a multipart request and immediately redirects to the queue screen.
- **Stage 1 Direct PLY/SPLAT Ingest**: Bypass training algorithms and upload pre-computed `.ply` or `.splat` files directly with geospatial tags.

### 4. ⚙️ Background Celery Reconstruction Queue
- Lists all active reconstruction tasks.
- Polls `GET /api/v1/jobs/capture/{capture_id}` in a lightweight 4s loop to retrieve live progress parameters (0-100%).
- Displays visual loaders mapping to worker milestones (extracting frames, variance calculations, Luma uploads).
- **Inspect Exception Log**: If a worker task fails, tap the button to load a scrollable terminal-style dialog showcasing raw server stdout tracebacks.

### 5. 🧊 3D WebGL Calibration Canvas
- Embeds our high-performance WebGL Gaussian Splat renderer in a webview.
- Supports smooth multi-touch gestures (one-finger drag to orbit, two-finger pinch to zoom, three-finger drag to pan).
- **Live Calibration Console**: Slide selectors adjusting Pitch, Yaw, Roll and uniform Scale factors. Adjusting a slider instantly fires JavaScript hooks (`window.updateCalibration`) to realign the 3D model in real time.
- Tap **Save Orientation** to commit calibration offsets to the FastAPI SQL database via a `PATCH /api/v1/splats/{id}` request.

---

## 💻 Local Development & Execution

To test the application locally:

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system. You can verify this by running:
```bash
flutter doctor
```

### 2. Configure Packages & Dependencies
Verify and fetch required visual mapping assets and core http libraries:
```bash
flutter pub get
```

### 3. Set Up Target Backend
By default, the application attempts to communicate with the FastAPI server running on `http://127.0.0.1:8000`. You can change this base URL dynamically from the Settings dialog on the Home Dashboard inside the app.

To boot the backend alongside (if working locally):
```bash
# In the disaster_gaussian_splatting backend directory
uvicorn app.main:app --reload
```

### 4. Start the Application
Execute a dev server or launch the mobile emulator:
```bash
flutter run
```

---

## ⚡ Integration Details & API Contracts

The application binds to the strict Pydantic schemas served by the FastAPI web service:

| Feature / Action | HTTP Method | Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Splat Registration** | `POST` | `/api/v1/splats/` | Registers geospatial coordinate shell metadata |
| **Direct Asset Upload** | `POST` | `/api/v1/splats/{id}/upload-asset` | Uploads a `.ply` or `.splat` file directly (Stage 1) |
| **Radius search** | `GET` | `/api/v1/splats/search` | Performs radial haversine filtering on geolocated splats |
| **Update Calibration** | `PATCH` | `/api/v1/splats/{id}` | Calibrates Pitch, Yaw, Roll and scaling factors |
| **Delete splat** | `DELETE` | `/api/v1/splats/{id}` | Removes capture from PostgreSQL database and deletes binary from disk |
| **Trigger video build** | `POST` | `/api/v1/jobs/upload-video` | Commits MP4 files to OpenCV queue (Stage 2) |
| **Poll Celery Job** | `GET` | `/api/v1/jobs/capture/{id}` | Fetches active pipeline status messages & percentages (0-100%) |
