# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.3.x   | :white_check_mark: |
| < 0.3   | :x:                |

## Reporting a Vulnerability

We take the security of OSDCloudCustomBuilder seriously. If you believe you've found a security vulnerability, please follow these steps:

1. **Do not disclose the vulnerability publicly**
2. **Email us** at security@example.com with details about the issue
3. Allow time for us to respond and address the issue before any public disclosure
4. We will acknowledge receipt within 48 hours and provide an estimated timeline for a fix

## Security Considerations

This module is designed to create and customize Windows PE images. Please be aware that:

- Custom images should be created in controlled environments
- Scripts included in WinPE should be thoroughly vetted before deployment
- Administrator privileges are required for many operations

## Validation

All releases are signed and can be validated using standard PowerShell signature verification:

```powershell
Get-AuthenticodeSignature -FilePath ".\OSDCloudCustomBuilder.psm1"
```
