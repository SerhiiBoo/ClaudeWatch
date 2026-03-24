# Contributing to Claude Watch

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. **Requirements**: macOS 14+ and Swift 5.9+
2. Clone the repo:
   ```bash
   git clone https://github.com/SerhiiBoo/ClaudeWatch.git
   cd ClaudeWatch
   ```
3. Build and run:
   ```bash
   make run
   ```

## How to Contribute

### Reporting Bugs

- Use the [Bug Report](https://github.com/SerhiiBoo/ClaudeWatch/issues/new?template=bug_report.md) issue template
- Include your macOS version and steps to reproduce
- Attach a screenshot if the issue is visual

### Suggesting Features

- Use the [Feature Request](https://github.com/SerhiiBoo/ClaudeWatch/issues/new?template=feature_request.md) issue template
- Explain the use case, not just the solution

### Submitting Code

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test locally: `make build`
5. Commit with a clear message
6. Push and open a Pull Request

### Pull Request Guidelines

- Keep PRs focused on a single change
- Update the README if you add user-facing features
- Ensure the project builds cleanly (`make build`)
- Follow existing code style (SwiftUI, MVVM pattern)

## Code Style

- **Architecture**: MVVM with SwiftUI
- **File organization**: one concern per file, grouped by feature (Models, Services, Views)
- **Immutability**: prefer `let` over `var`, use value types
- **Error handling**: handle errors explicitly, provide user-friendly messages
- **No external dependencies**: this project uses only Apple frameworks

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
