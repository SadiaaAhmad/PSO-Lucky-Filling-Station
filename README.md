# ⛽ PSO Lucky Filling Station — Accounting & Operations System

<p align="center">
  <img src="https://img.shields.io/badge/Frontend-Flutter_3-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Python-3.14-3776AB?logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Database-SQLite%20%2F%20PostgreSQL-003B57?logo=sqlite&logoColor=white" alt="Database">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

An enterprise-grade financial accounting and daily shift operations management system built specifically for **PSO (Pakistan State Oil) Filling Stations**. 

The system automates dispenser meter reconciliations, underground storage tank (UST) physical dip variance tracking, fuel lorry delivery inventory valuation, credit (udhaar) customer management, operating expenses, and double-entry general ledger accounting.

---

## 🌟 Key Features

* **⛽ Dispenser Nozzle Reconciliation**: Real-time meter reading tracking across 6 dispensing units (HSD & PMG) with automatic gross and net sales calculation.
<img width="299" height="602" alt="image" src="https://github.com/user-attachments/assets/eaf93b0d-6c5a-4965-97bc-d34d9f79c274" />

* **📏 Tank Dip & Stock Loss Control**: Computes expected closing stocks against actual physical tank dips to track stock gain/loss variances in both Liters and PKR.
<img width="301" height="604" alt="image" src="https://github.com/user-attachments/assets/91f3cd91-e93a-4d7f-82a8-60995ba1d339" />

* **💳 PSO Card & Fleet Sales**: Automatic reconciliation of PSO Bank Card Sales and BPSO Fleet Cards with bank commission deductions.
<img width="300" height="604" alt="image" src="https://github.com/user-attachments/assets/77f46a5d-0224-4803-9c7a-784b9b164aa4" />

* **📖 Double-Entry Accounting Ledger**: Automated journal entry generation for assets, liabilities, revenue, and operating expenses.
<img width="298" height="600" alt="image" src="https://github.com/user-attachments/assets/58119166-851f-485a-b288-de83b58f0b7d" />
<img width="301" height="603" alt="image" src="https://github.com/user-attachments/assets/39fed59d-bbc7-4b3a-9f3d-768dcc680d60" />

* **🤝 Udhaar (Credit) Customer Accounts**: Customer credit limits, balance tracking, repayment recoveries, and aging reports.
<img width="300" height="606" alt="image" src="https://github.com/user-attachments/assets/689cbb25-a47e-4099-a13f-27e07eb3bb16" />

* **📊 Financial Statements & Reports**: Monthly Profit & Loss (P&L) statements, Daily Shift Reports, Udhaar Summaries, and 1-click **PDF & Excel exports**.
<img width="299" height="606" alt="image" src="https://github.com/user-attachments/assets/abeae719-cef6-46fb-b3ff-797f598c6e4d" />

* **⚡ Auto-Discovery & Zero-Config Setup**: Automatic local network pairing between mobile phones and host PC with background server automation.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Mobile & Desktop Frontend** | Flutter (Dart) — Cross-platform iOS, Android, and Desktop |
| **REST API Backend** | FastAPI (Python 3.14) with Uvicorn ASGI Server |
| **Database & ORM** | SQLite / PostgreSQL with SQLAlchemy ORM & Alembic migrations |
| **Networking** | Self-healing local Wi-Fi IP auto-discovery client (`ApiClient`) |

---

## 🚀 Quick Start Guide (Desktop / Laptop)

### 1. Prerequisites
* [Python 3.10+](https://www.python.org/downloads/)
* [Flutter SDK 3.x+](https://docs.flutter.dev/get-started/install)

### 2. Backend Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/SadiaaAhmad/PSO-Lucky-Filling-Station.git
   cd PSO-Lucky-Filling-Station
   ```
2. Install Python dependencies:
   ```bash
   pip install -r backend/requirements.txt
   ```
3. Launch the Backend Server:
   - **Option A (Manual)**:
     ```bash
     python -m uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
     ```
   - **Option B (1-Click Batch File)**: Double-click `start_backend.bat` in the project root.
   - **Option C (100% Silent Background Service)**: Double-click `run_backend_silent.vbs`. *(To run automatically when your PC boots, copy `run_backend_silent.vbs` to your Windows Startup folder: `Win + R` ➔ type `shell:startup`).*
   - **Option D (24/7 Free Cloud Hosting — Laptop can be OFF)**: Follow the step-by-step [24/7 Cloud Deployment Guide](file:///c:/Users/Sadia%20Ahmad/FuelStationAccounting/DEPLOYMENT.md) to host your backend on **Render.com** and **Neon.tech** for free!

---

## 📱 How to Run & Connect on Mobile Phones (Android / iOS)

The mobile app includes **Automatic Network Auto-Discovery** — it automatically finds your computer's IP address on your local network!

### Method 1: Connecting via Local Wi-Fi (Wireless)

1. **Connect to Same Wi-Fi**: Ensure both your **Mobile Phone** and **Computer** are connected to the same Wi-Fi network.
2. **Start Backend**: Ensure the FastAPI backend server is running on your PC (`start_backend.bat` or background service).
3. **Launch Mobile App**: Open the Flutter app on your phone.
4. **Auto-Pairing**: The app will automatically probe the local Wi-Fi network (`192.168.1.X`, etc.), locate the active server, and connect instantly **without typing any IP address!**

---

### Method 2: Connecting via USB Cable (ADB Reverse - Recommended for Android Developers)

1. Connect your phone to your PC via USB cable and enable **USB Debugging**.
2. Run ADB port forwarding command in terminal:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
3. Run the app on your physical device:
   ```bash
   cd frontend
   flutter run
   ```
4. The app will connect directly to `http://127.0.0.1:8000`.

---

### Method 3: Building Standalone APK for Android Phone Installation

To install the app directly on an Android device without keeping it connected to a computer:

1. Build the release APK:
   ```bash
   cd frontend
   flutter build apk --release
   ```
2. The generated APK file will be located at:
   `frontend/build/app/outputs/flutter-apk/app-release.apk`
3. Transfer `app-release.apk` to your Android phone via USB/WhatsApp/Drive and tap to install!

---

## 📁 Repository Structure

```
PSO-Lucky-Filling-Station/
├── backend/                  # FastAPI Backend API
│   ├── app/                  # Controllers, Models, Schemas & Services
│   ├── seed/                 # Seeding scripts for initial fuel rates & accounts
│   └── requirements.txt      # Python dependencies
├── frontend/                 # Flutter Mobile & Desktop Application
│   ├── lib/
│   │   ├── core/             # Theme, Utilities, Formatters & Widgets
│   │   ├── models/           # Data Models
│   │   ├── screens/          # Dashboard, Operations, Stock, Finance & Reports
│   │   └── services/         # ApiClient & ApiServices
│   └── pubspec.yaml          # Flutter dependencies
├── run_backend_silent.vbs    # Silent background server launcher
├── start_backend.bat         # 1-Click interactive server launcher
└── README.md                 # System documentation
```

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
