You are acting as an expert Senior Embedded Systems and Cross-Platform Flutter Architect. I am providing our project's absolute source of truth specification file: `airules.md`. 

Your core directives for this entire session are:
1. **Strict Adherence:** Every piece of code, state model, or architectural layout you generate must conform perfectly to the data dictionaries, pin maps, timing loops, coordinates, and BLE constraints detailed in this file.
2. **Zero Assertions/Hallucinations:** If a feature, state, or variable is explicitly listed as a hardware limitation (e.g., the phone being currently blind to live game scores/death states over BLE), do not write automated tracking logic or persist data for it unless I ask you to build a workaround.
3. **Architecture Match:** Our frontend is a Flutter application utilizing Riverpod for local state management. All data models must perfectly align with the pipe-delimited ASCII telemetry string (`STATE|MODE|BAT...`) parsing logic.

Please ingest and analyze the `airules.md` file provided below. Once you have digested it, do not write any code yet. Instead, reply with a concise 3-bullet summary confirming your understanding of:
- The exact BLE command size limit and handshake order rules.
- The UI behaviors mandated by TP4056 charging pin states.
- The physical layout coordinates for the Homepage Mode (`MODE_IDLE`) display elements.

This will confirm your context is locked in so we can immediately skip the basics and dive straight into building specific sub-systems.

============================================
# airules.md — TableBot Global Specification

## 1. System Overview & Architecture
TableBot is an interactive desktop companion operating on a split-codebase architecture:
* **Firmware Backend:** ESP32-S3 running C++ using the `NimBLE` framework (highly optimized for low memory footprint).
* **Frontend Controller:** Flutter mobile/desktop application utilizing Riverpod for local state management.
* **Execution Engine:** Asynchronous, non-blocking cooperative time-slice scheduler within a single main loop execution thread (no multi-threading RTOS overhead).

### Scheduler Timing Slots & Task Intervals
The firmware processes concurrent tasks strictly at these intervals:
* **20ms (`INTERVAL_BLE`):** Polls inbound phone commands and updates connection indicators.
* **20ms (`INTERVAL_ANIM`):** Refreshes OLED graphics canvas updates, UI rendering, and the game loop engine (50 FPS target).
* **50ms (`INTERVAL_INPUT`):** Samples edge-triggered physical touch sensors (debounced).
* **50ms (`INTERVAL_SERVO`):** Computes smooth step-wise servo angular interpolation tracking.
* **1000ms (`INTERVAL_CLOCK`):** Computes core runtime clock metrics (HH:MM:SS, Calendar dates).
* **5000ms (`INTERVAL_IDLE_CHECK`):** Evaluates system state flags to determine if sleep sequences should initiate.
* **5000ms (`INTERVAL_STATUS`):** Encapsulates and broadcasts the runtime ASCII telemetry string over BLE.
* **8000ms (`INTERVAL_RANDOM_LOOK`):** Directs spontaneous servo glances (Only active when system is in `STATE_IDLE` + `MODE_IDLE`).
* **30000ms (`INTERVAL_BATTERY`):** Executes ADC sampling of battery health metrics and power supply rails.
* **10 min (`INTERVAL_WEATHER`):** Performs network sync with weather endpoints via the phone's location pipeline.
* **1 hr (`INTERVAL_NTP`):** Re-aligns internal clock drift with network time protocol servers (`pool.ntp.org`).

---

## 2. Hardware Mapping & Pin Configuration
All hardware pins conform strictly to the ESP32-S3 Supermini layout rules defined below. No other pin configurations or aliases are permitted anywhere else in the firmware codebase.

* **OLED Display (I2C):** SDA = `GPIO 8`, SCL = `GPIO 9` (Drives a 3.3V SH1106 128x64 display via U8g2).
* **Microphone Input (INMP441 I2S):** SD = `GPIO 4`, WS = `GPIO 5`, SCK = `GPIO 6` (Mono mode, L/R bound to GND).
* **Audio Amplifier (MAX98357 I2S):** DIN = `GPIO 7`, BCLK = `GPIO 15`, LRC = `GPIO 16`, SD_MODE = `GPIO 17`.
* **Touch Sensor Deck (TTP223):** Main Touch (Sensor 1) = `GPIO 2`, Game Touch (Sensor 2) = `GPIO 14`.
* **Actuation Layer:** Servo PWM Output = `GPIO 13` (Constrained to 5V power rails, driven by ESP32Servo).
* **Visual Status Array:** Blue LED (BLE Status) = `GPIO 38`, Red LED (Charge Warning) = `GPIO 41`.
* **Power Management Architecture:**
  * Battery Monitor Input = `GPIO 1` (Bound to ADC1_CH0 via an external 100kΩ/100kΩ voltage divider mesh).
  * TP4056 CHRG Pin = `GPIO 39` (Active LOW, indicates active charging loop).
  * TP4056 STDBY Pin = `GPIO 40` (Active LOW, indicates battery charging cycle complete).
* **Hardware Debug Intercepts:** UART TX = `GPIO 43`, UART RX = `GPIO 44` (Strictly reserved for serial terminal communication).

---

## 3. Network Identity & Communication Protocol
The phone and bot establish automated communication pipelines using hardcoded hardware profiles.

### Wi-Fi Configuration Identity
* **Captive Portal SSID:** `TableBot-Setup`
* **Behavior:** If local network credentials are missing or fail, the bot establishes a local access point with this broadcast name. The Flutter app must direct users to connect to this network for setup.
* **Default Coordinates Fallback:** If no location update is sent over BLE, the bot defaults to Kollam, Kerala (`Latitude: 8.8932`, `Longitude: 76.6141`).

### Connection Hardware Profiles
* **Broadcast Name:** `TableBot`
* **Service UUID:** `12345678-1234-1234-1234-123456789abc`
* **Command Characteristic (Write):** `12345678-1234-1234-1234-123456789abd`
* **Status Characteristic (Notify/Read):** `12345678-1234-1234-1234-123456789abe`

### Packet Size & Handshake Limits
1. **Command Size Limit:** The firmware buffers incoming text commands into a fixed character array: `char lastCommand[32]`. **Flutter commands must never exceed 31 characters** (+1 null terminator).
2. **App Transmission Throttle:** Because the ESP32 polls for commands every 20ms, the Flutter application must debounce or throttle high-frequency streams (e.g., manual servo sliders) to prevent packet loss or buffer corruption.
3. **Connection Handshake Order:** Flutter must strictly request an MTU upgrade to `512` bytes *after* a successful connection state change, but *before* subscribing to the status characteristic notification stream.

---

## 4. Data Dictionary & Hardcoded Contracts

### Outgoing Telemetry Payload (Bot → Phone Stream)
The bot broadcasts its state sequentially over the status characteristic every 5000ms as a pipe-delimited ASCII string:
`STATE:%d|MODE:%d|BAT:%d|TEMP:%.1f|WIFI:%d`

#### Core System State (`STATE`)
* **0 (`STATE_IDLE`):** Normal layout view (Show face, clock, weather).
* **1 (`STATE_ACTIVE`):** Highlighted dashboard layout / active feedback state.
* **2 (`STATE_SLEEPING`):** Dim interface / Low power standby layout (OLED off).
* **3 (`STATE_UPDATING`):** Execution blocking firmware/network sync state.
* **4 (`STATE_ERROR`):** Critical internal failure trap. Overlays safety warnings.

#### Bot Mode (`MODE`)
* **0 (`MODE_IDLE`):** Default telemetry dashboard.
* **1 (`MODE_FOCUS`):** Minimalist layout (Mute buttons enabled, large clock visible).
* **2 (`MODE_GAME`):** Game engine active. Bypasses standard face layers to display retro arcade application.

#### Face Expressions (`FaceExpression`)
Parsed sequentially from `bot_state.h`:
* **0:** `FACE_HAPPY`
* **1:** `FACE_NEUTRAL`
* **2:** `FACE_SLEEPY`
* **3:** `FACE_FOCUSED`
* **4:** `FACE_SAD`

### Outgoing Urgent Alerts (Bot → Phone Messages)
Spontaneous event notifications are dispatched independently via `BLE_sendMessage`:
* **`"ALERT:BATTERY_CRITICAL"`**: Triggered when the battery percent falls below 10%. The Flutter app must instantly overlay a critical modal alert dialog.

### Inbound Token Directives (Phone → Bot Commands)
Commands sent from the Flutter interface to the firmware parsing layer must match these uppercase schemas byte-for-byte:
* **Set Modes:** `"MODE:IDLE"`, `"MODE:FOCUS"`, or `"MODE:GAME"`
* **Volume Calibration:** `"VOL:<integer>"` (Bounded between `0` and `100`).
* **Location Sync:** `"LAT:<float>,LON:<float>"` (Processed via direct token pointer jumps. **Strict Requirement:** Must contain absolutely zero whitespace characters).

---

## 5. Digital Twin Graphics & Game Engine Mapping

### Canvas Dimensions & Proportions
* **Fixed Display Aspect Ratio:** Strict 2:1 bounds.
* **Virtual Coordinate Resolution Matrix:** `128 x 64` pixels.

### Flappy Bird Physics Engine Constraints (`MODE_GAME`)
* **Frame Step Execution:** Logic advances synchronously on a rigid 20ms step interval (`INTERVAL_ANIM`).
* **Gravity Acceleration Model:** `0.25` pixels/frame² applied downward constantly to the vertical velocity vector.
* **Flap Impulse Threshold:** Actuating a jump forces vertical velocity immediately to `-2.8` pixels/frame.
* **Horizontal Translation Vector:** Obstacle pipes scroll from right to left at a fixed step of `2` pixels/frame.
* **Bird Structural Footprint:** Locked horizontally to position coordinate $X = 30$. Shape geometry is a circle with a radius of `3` pixels.
* **Pipe Architecture Constraints:** Individual obstacle pipe width is `14` pixels. The open safety passage pass-through gap is a fixed height of `26` pixels.
* **Map Generation Constraints:** The top pipe's bottom edge varies between $Y = 8$ and $Y = 38$ via a pseudo-random integer sequence generator (`random(8,38)`).

### Real-Time Play Monitoring & High Scores
* **Play Phase States:** The game lifecycle is derived from `bot.game` structure values:
  * *Splash Screen Phase:* `isDead == false` and `score == 0`.
  * *Active Play Phase:* `isDead == false` and `score > 0`.
  * *Game Over / Death Phase:* Evaluated the exact millisecond `isDead` transitions to `true`.
* **Telemetry Limitations & Offloading:** The current outgoing telemetry payload (`STATE|MODE|BAT...`) does **not** yet stream live game scores or death notifications. Until the firmware developer adds `score` and `isDead` variables to the BLE broadcast string, the phone application cannot track live play or handle automated high score archiving.

### Dynamic Layout Profiles

#### A. Homepage Layout Mode (`MODE_IDLE`)
* **Time Layout Anchor:** Top-left string position at `(0, 10)`.
* **Weather Temperature Layout Anchor:** Top-right string position at `(94, 10)`.
* **Sub-Frame Face Enclosure Bounds:** A rounded rectangle outline plotted at `(18, 12)` with a width of `92` and height of `48` (Corner radius: `8`).
* **Mini-Eye Anchors:** Centered vertically down at height `Y = 32`. Left eye center `X = 45`, right eye center `X = 83`. Base circle radius is scaled down to `9` pixels.
* **Cheek Circles:** Drawn at `(30, 44)` and `(98, 44)` with a radius of `3` pixels.

#### B. Focus Layout Mode (`MODE_FOCUS`)
* **Giant Centered Clock:** Scaled using a large vertical format font centered along the X axis with a baseline layout anchor set to `Y = 42`.
* **Micro-Eyes Accent:** Positioned neatly above the time elements. Left eye center `X = 44`, right eye center `X = 84` at height `Y = 14` with a tight radius of `6` pixels.

#### C. Full-Screen Face Mode (`animation_engine.cpp` default)
* **Canvas Border Ring:** Corresponds to a rounded rectangle starting from `(0,0)` tracking to `(128,64)` with a corner radius of `8` pixels.
* **Eye Center Rows:** Hardcoded to vertical height coordinate `Y = 27`. Left eye fixed at `X = 38`, right eye fixed at `X = 90`. Base circle radius is `11` pixels.
* **Pupil Tracking Offsets:** Wander boundaries stay constrained to a maximum delta offset of $X = [-3, 3]$ and $Y = [-2, 2]$.
* **The Neutral Face Paradox:** When telemetry states broadcast `FACE_NEUTRAL` (Value: 1), the Flutter UI engine must draw the unique wavy mouth path (`_mouthWavy`) and a question mark string `?` rendered at coordinate location `(110, 20)` to accurately mirror the firmware display implementation.

### Telemetry Icon Elements
* **BLE Status Connection Dot:** Rendered as a small solid circle at `(122, 5)` with a radius of `3` pixels. Visible when `showBLEIcon` is enabled.
* **Battery Low Warning Symbol:** An exclamation point (`!`) stamped at the bottom left bounds `(0, 64)`. Visible when `showBatteryIcon` is enabled.

---

## 6. Automation & Hardware Overrides

### Autonomous State Shifts
The physical robot features autonomous loops that the app can monitor but cannot block:
* **Inactivity Sleep:** If the system stays in `STATE_IDLE` for 30 seconds (`IDLE_TIMEOUT_MS = 30000`), the firmware automatically triggers a transition to `STATE_SLEEPING`.
* **Game Mode Control Override:** If `bot.mode == MODE_GAME`, the auto-sleep timer is entirely deactivated. Physical Touch Sensor 1 is hijacked exclusively to serve as the game loop controller (`bot.game.flapPressed = true`).
* **Physical Game Toggle:** Tapping physical Touch Sensor 2 immediately enters or exits Game Mode on the fly. The Flutter app must be fully reactive and switch layouts dynamically when the status telemetry transitions to `MODE:2` or away from it.

### Servo Kinematics & The "Is Moving" Gating Law
Servo motor movements execute smooth interpolation tracking across a 50ms window (`INTERVAL_SERVO`).
* **Structural Hardware Limits:** The head servo is strictly clamped between `50°` (Max Left) and `130°` (Max Right). True center is locked at `90°`.
* **The "Is Moving" Gating Law:** The interpolation engine remains completely passive unless `bot.servo.isMoving` is explicitly toggled to `true`. External command files or mobile interface inputs must write `bot.servo.isMoving = true` whenever updating `bot.servo.targetAngle`, or the update will be entirely ignored by the motor.
* **State-Driven Interpolation Step Speeds:**
  * `STATE_SLEEPING` uses `SPEED_LAZY` (`3°` per tick) for slow head relaxation.
  * `STATE_IDLE` uses `SPEED_NORMAL` (`8°` per tick) for natural visual look animations.
  * `STATE_ACTIVE` / `STATE_ERROR` uses `SPEED_SNAP` (`15°` per tick) for instantaneous, alert responses.

### Focus Mode Power Down
When `"MODE:FOCUS"` is active, the bot drives `PIN_AMP_SD_MODE` (`GPIO 17`) to `LOW`. This cuts physical hardware power directly to the onboard audio amplifier circuit. The Flutter volume control interface should be visually greyed out/disabled while the bot is locked in Focus Mode to reflect this state accurately.

### Battery Charging Status UI Link
Using physical tracking data from the TP4056 pins (`GPIO 39` and `GPIO 40`), the Flutter application layout must parse charging logic via the following parameters:
* **Pin 39 LOW:** Display an animated lightning bolt charging status icon.
* **Pin 40 LOW:** Display a solid full battery/plugged-in completed charging state icon.
* 