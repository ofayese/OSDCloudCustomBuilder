# Contributing to OSDCloudCustomBuilder

Thank you for helping improve this module!

## 🛠️ Setup

1. Clone the repo
2. Open in VS Code inside dev container (`.devcontainer`)
3. Run `Invoke-Pester -Path ./tests` before commits

## 🧪 Linting & Tests

```powershell
Invoke-ScriptAnalyzer -Path ./ -Recurse
Invoke-Pester -Path ./tests
```

## 📋 Checklist

- [ ] New functions have help comments
- [ ] Function docs added in `docs/functions/`
- [ ] CI passes

See `.github/PULL_REQUEST_TEMPLATE.md` for full checklist.
