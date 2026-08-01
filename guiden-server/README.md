# Guiden Python AI Navigation Server 🚀

> **FastAPI WebSocket backend server powering real-time visual navigation, Gemini 2.0 Flash Vision AI, and ElevenLabs speech synthesis.**

---

## ⚡ Quick Start

### Step 1: Navigate to Server Directory
```bash
cd guiden-server
```

---

### Step 2: Create & Activate Virtual Environment

#### On Linux / macOS:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

#### On Windows (PowerShell):
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

---

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

---

### Step 4: Export API Keys

#### On Linux / macOS:
```bash
export GEMINI_API_KEY="your_google_gemini_api_key_here"
export ELEVENLABS_API_KEY="your_elevenlabs_api_key_here"
```

#### On Windows (PowerShell):
```powershell
$env:GEMINI_API_KEY="your_google_gemini_api_key_here"
$env:ELEVENLABS_API_KEY="your_elevenlabs_api_key_here"
```

---

### Step 5: Launch Uvicorn Server
```bash
uvicorn assist_server:app --host 0.0.0.0 --port 8765 --reload
```

---

## 🔌 Server Endpoints

| Endpoint Path | Type | Description |
| :--- | :--- | :--- |
| `ws://0.0.0.0:8765/ws/stream` | WebSocket | High-speed camera frame streaming & real-time guidance voice responses. |
| `http://0.0.0.0:8765/health` | HTTP GET | Server health check endpoint. |
