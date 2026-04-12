# Flutter Event Component System Inspector

A small DevTools inspector project that complements the `flutter_event_component_system` core package. It builds a DevTools extension containing visual tools for inspecting features, entities, events, and system interactions at runtime.

## Purpose

- Provide a visual debugging surface for ECS-based apps
- Ship a DevTools extension that can be loaded by the `ecs` package during development

## Prerequisites

- Dart & Flutter SDK installed
- `devtools_extensions` package available (used by the build scripts)

## Build & Install (development)

Build the DevTools extension and copy it into the `ecs` package extension folder:

```bash
dart run devtools_extensions build_and_copy --source=. --dest=../ecs/extension/devtools
```

Validate the extension package (run from this folder):

```bash
dart run devtools_extensions validate --package=../ecs
```

After copying, run your Flutter app that uses the `ecs` package and open DevTools. The inspector extension should appear in the DevTools extensions list.

## Development notes

- The extension sources live in this project and are packaged into the DevTools extension build by `devtools_extensions`.
- To iterate quickly, rebuild and copy the extension after making UI changes.
