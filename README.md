# Flutter Event Component System — Monorepo

A collection of packages, tools, and examples for the Flutter Event-Component-System (ECS) ecosystem.

This repository contains the core ECS runtime, a build_runner generator, an inspector/devtools extension, and benchmark/example projects.

## Projects

- [ecs](ecs/README.md): Core library implementing the Event-Component-System patterns for Flutter (components, events, systems, and widget integration).
- [generator](generator/README.md): `build_runner` code generator that converts declarative ECS feature definitions into concrete classes.
- [inspector](inspector/README.md): DevTools / inspector tooling for visualizing ECS state and system interactions.
- [benchmark](benchmark/README.md): Benchmark and example Flutter project demonstrating ECS usage.

## Repository layout

- `ecs/` — core package and runtime
- `generator/` — code-generator package
- `inspector/` — devtools inspector project
- `benchmark/` — example/benchmark Flutter app

## Quick Links

- Core package README: [ecs/README.md](ecs/README.md)
- Generator docs: [generator/README.md](generator/README.md)
- Inspector docs: [inspector/README.md](inspector/README.md)
- Benchmarks & examples: [benchmark/README.md](benchmark/README.md)

## Quick Commands

Run tests (top-level):

```bash
dart test
```

Run the generator in the `generator` package (example):

```bash
cd generator
dart run build_runner build --delete-conflicting-outputs
```

Publish the `generator` package to pub.dev (make sure to update `version` in `generator/pubspec.yaml` first):

```bash
cd generator
dart pub publish
```

## Contributing

Contributions are welcome. Please open issues or PRs in this repository. See each subproject README for package-specific development and testing instructions.

## License

This repository is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.
