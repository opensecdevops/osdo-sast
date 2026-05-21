# osdo-sast

> Part of the [OSDO Framework](https://github.com/opensecdevops/osdo) — Open SecDevOps

Static Application Security Testing with Semgrep, CodeQL, and language-specific analyzers

## Quick Start

```yaml
- uses: opensecdevops/osdo-sast@v2
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `path` | Path to scan for security vulnerabilities | No | `.` |
| `language` | Programming language (auto, python, javascript, typescript, go, java, csharp, ruby, all) | No | `auto` |
| `scanners` | Scanners to use (semgrep, codeql, bandit, eslint, all) | No | `semgrep` |
| `severity-threshold` | Minimum severity to report (INFO, WARNING, ERROR) | No | `WARNING` |
| `fail-on-finding` | Fail the action if vulnerabilities are found | No | `true` |
| `semgrep-rules` | Semgrep ruleset (auto, p/security-audit, p/owasp-top-ten, p/cwe-top-25, custom path) | No | `auto` |
| `results-dir` | Directory to store results | No | `.osdo/results` |

## Outputs

| Output | Description |
|--------|-------------|
| `findings` | Total vulnerabilities found |
| `critical-count` | Critical severity count |
| `high-count` | High severity count |
| `sarif-file` | Path to SARIF output file |

## Example

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: opensecdevops/osdo-sast@v2
        with:
          path: "."
          language: "auto"
          scanners: "semgrep,codeql"
          severity-threshold: "WARNING"
          fail-on-finding: "true"
          semgrep-rules: "p/security-audit"
```

## Part of OSDO

This action is part of the [OSDO Framework](https://github.com/opensecdevops/osdo). Use it standalone or combine with other OSDO actions:

- [osdo-sast](https://github.com/opensecdevops/osdo-sast) — Static Analysis
- [osdo-sca](https://github.com/opensecdevops/osdo-sca) — Dependency Scanning
- [osdo-secrets-scan](https://github.com/opensecdevops/osdo-secrets-scan) — Secret Detection
- [osdo-container-scan](https://github.com/opensecdevops/osdo-container-scan) — Container Security
- [osdo-iac-scan](https://github.com/opensecdevops/osdo-iac-scan) — IaC Scanning
- [osdo-sbom](https://github.com/opensecdevops/osdo-sbom) — SBOM Generation
- [osdo-sign](https://github.com/opensecdevops/osdo-sign) — Artifact Signing

## License

Apache-2.0
