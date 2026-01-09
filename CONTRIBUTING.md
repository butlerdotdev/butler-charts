# Contributing to Butler Charts

Thank you for your interest in contributing to Butler Charts! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.

## Developer Certificate of Origin

By contributing to this project, you agree to the Developer Certificate of Origin (DCO). This document was created by the Linux Kernel community and is a simple statement that you, as a contributor, have the legal right to make the contribution.

Every commit must be signed off:

```bash
git commit -s -m "Your commit message"
```

## Getting Started

### Prerequisites

- Helm 3.12+
- kubectl
- A Kubernetes cluster for testing (KIND works well)

### Setting Up Your Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/butler-charts.git
   cd butler-charts
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/butlerdotdev/butler-charts.git
   ```

### Project Structure

```
butler-charts/
├── charts/                    # Individual Helm charts
│   ├── butler-crds/          # Custom Resource Definitions
│   ├── butler-bootstrap/     # Bootstrap controller
│   ├── butler-controller/    # TenantCluster controller
│   ├── butler-provider-*/    # Infrastructure providers
│   └── butler-console/       # Web console
├── profiles/                  # Deployment profiles (edge, core)
├── scripts/                   # Build and release scripts
├── .github/workflows/         # CI/CD automation
└── docs/                      # Additional documentation
```

## Making Changes

### Chart Development Guidelines

1. **Follow Helm Best Practices**
   - Use templates for reusability
   - Validate with `helm lint`
   - Include comprehensive `values.yaml` documentation
   - Use semantic versioning

2. **Naming Conventions**
   - Chart names: lowercase, hyphenated (e.g., `butler-controller`)
   - Template names: `_helpers.tpl` for shared templates
   - Label selectors: use `app.kubernetes.io/*` labels

3. **Required Chart Files**
   - `Chart.yaml` - Chart metadata
   - `values.yaml` - Default configuration
   - `README.md` - Documentation
   - `templates/NOTES.txt` - Post-install notes
   - `templates/_helpers.tpl` - Template helpers

4. **Testing**
   - Test with `helm template` for rendering
   - Deploy to a test cluster before submitting
   - Include both edge and core profile testing

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
Signed-off-by: Your Name <your.email@example.com>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code refactoring

### Pull Request Process

1. Create a feature branch:
   ```bash
   git checkout -b feat/your-feature
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -s -m "feat(controller): add new configuration option"
   ```

3. Push to your fork:
   ```bash
   git push origin feat/your-feature
   ```

4. Open a Pull Request against `main`

5. Ensure all checks pass:
   - Helm lint
   - Chart template validation
   - Version consistency

### Versioning

- Chart versions follow [SemVer](https://semver.org/)
- Each chart has independent versioning
- `appVersion` reflects the application version (e.g., controller image tag)
- Bump versions in `Chart.yaml` when making changes

### Testing Charts

```bash
# Lint a chart
helm lint charts/butler-controller

# Render templates locally
helm template butler-controller charts/butler-controller

# Render with custom values
helm template butler-controller charts/butler-controller -f profiles/edge.yaml

# Install to test cluster
helm install butler-controller charts/butler-controller --dry-run

# Package chart
helm package charts/butler-controller
```

## Release Process

Releases are automated via GitHub Actions:

1. Update chart version in `Chart.yaml`
2. Create a PR with version bump
3. After merge, tag the release:
   ```bash
   git tag butler-controller-v0.2.0
   git push origin butler-controller-v0.2.0
   ```
4. CI/CD will automatically:
   - Package the chart
   - Push to GHCR OCI registry
   - Create GitHub release

## Getting Help

- Open an issue for bugs or feature requests
- Join our community discussions
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
