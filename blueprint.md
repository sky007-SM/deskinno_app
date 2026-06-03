# Project Blueprint: TableBot Controller

## 1. Core Purpose & System Architecture

This Flutter application serves as the primary user interface and remote controller for the **TableBot**, an ESP32-based interactive desktop companion. The application communicates with the firmware over Bluetooth Low Energy (BLE) using a strict data contract defined in `airules.md`.

- **Frontend:** Flutter with Riverpod for state management.
- **Backend Communication:** BLE via `flutter_blue_plus`.
- **Design & Layout:** Adheres to the layout and state definitions in `airules.md`.

---

## 2. Implemented & Planned Features

### Feature 2.1: BLE Connection & Telemetry
- **Status:** Implemented
- **Description:** The app scans for, connects to, and communicates with the TableBot. It parses incoming telemetry strings to display the bot's state, mode, battery level, and other vital signs in real-time. It also sends user commands back to the bot.

### Feature 2.2: Automatic Update Checker
- **Status:** In Progress
- **Description:** On application startup, the app will make a network request to the official GitHub repository to check for the latest software release. If the version tag of the latest release is newer than the currently installed app version, a non-intrusive dialog will appear, prompting the user to download and install the update.
- **GitHub Repository:** `https://github.com/sky007-SM/INNO_BOT_APP`
