# ECS Benchmark

A Flutter example and benchmark app demonstrating usage of the `flutter_event_component_system` core package and measuring basic system performance.

## Overview

This project is an example application and lightweight benchmark intended to:

- demonstrate how to integrate `flutter_event_component_system` into a Flutter app
- provide a simple harness for profiling and measuring system update performance

## Requirements

- Flutter SDK (stable channel)
- A connected device, emulator, or desktop target (Windows/Linux/macOS) supported by Flutter

## Getting started

Install dependencies:

```bash
flutter pub get
```

Run the app (choose an available device):

```bash
flutter run
```

Run on a specific desktop device (example):

```bash
flutter run -d windows
```

## Running benchmarks / profiling

To get meaningful performance measurements, run the app in `profile` or `release` mode:

```bash
flutter run --profile -d <device>
flutter build windows --release   # build a release for Windows
```

Use platform profiling tools (DevTools, Windows Performance Analyzer, etc.) to collect traces and CPU/memory data.

## Project structure

- `lib/` — example app source and benchmsark harness
- `pubspec.yaml` — package dependencies
- `windows/` — desktop build files (if present)

## Notes

- The benchmark is intended as a lightweight example and may not represent production workloads.
