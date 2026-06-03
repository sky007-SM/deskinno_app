
# TableBot Controller - Blueprint

## 1. Project Overview

This document outlines the features, design, and implementation plan for the TableBot Controller Flutter application. The app serves as the primary user interface for interacting with the TableBot hardware.

## 2. Style and Design Guide

The application will adhere to a modern, clean, and visually engaging design aesthetic.

*   **Color Palette:**
    *   **Primary Background:** A dark, slightly textured charcoal (`#1A1A1A`).
    *   **Primary Accent:** A vibrant, futuristic blue (`#00BFFF`).
    *   **Secondary Accent / Success:** A bright green (`#00FF7F`).
    *   **Warning / Error:** A sharp red (`#FF4500`).
    *   **Font Color:** Off-white (`#F5F5F5`).
*   **Typography:** The `Poppins` font family from Google Fonts will be used for its clean, modern, and friendly appearance.
*   **Iconography:** We will use the standard Material Design icons, ensuring they are clear and intuitive.
*   **Visual Effects:** Subtle "glow" effects on interactive elements and soft shadows will be used to create a sense of depth and interactivity.

## 3. Current Implementation Plan: Initial User Flow

This plan details the steps to create a complete and polished initial user experience, from app launch to device connection.

### Actionable Steps:

1.  **Add Dependencies:**
    *   Add the `google_fonts` package for custom typography.
    *   Add `lottie` for engaging animations on the landing screen.
2.  **Create Themed App Shell:**
    *   Update `main.dart` to implement the defined color palette and typography as the global app theme.
3.  **Build Animated Landing Screen (`landing_screen.dart`):**
    *   Create a new, visually rich landing screen.
    *   This screen will display an animation (e.g., a searching radar or a welcome robot) using Lottie.
    *   It will automatically check for Bluetooth permissions.
    *   Upon success, it will navigate to the device scanning screen.
4.  **Develop BLE Scanner Provider (`ble_provider.dart`):**
    *   Create a new Riverpod provider to manage all Bluetooth Low Energy (BLE) state and logic.
    *   This provider will handle:
        *   Requesting permissions (`permission_handler`).
        *   Starting and stopping BLE device scans (`flutter_blue_plus`).
        *   Managing the list of discovered devices.
        *   Handling device connection and disconnection.
5.  **Build Device Scanner Screen (`scanner_screen.dart`):**
    *   Create a dedicated screen to display the results of the BLE scan.
    *   It will show a list of discovered devices, specifically filtering for devices named "TableBot" as per `airules.md`.
    *   Each list item will be interactive, allowing the user to tap to initiate a connection.
    *   A "Rescan" button will be available.
6.  **Implement Navigation:**
    *   The `main.dart` file will be updated to show the `LandingScreen` first.
    *   Navigation will be handled based on the BLE permission and connection status.
        *   **Launch -> Landing Screen -> (Permissions OK) -> Scanner Screen -> (Connection OK) -> Dashboard Screen**
