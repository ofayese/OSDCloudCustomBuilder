# Pull Request

## Description

Please provide a clear and concise description of the changes in this pull request.

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring
- [ ] Test improvement

## Related Issues

Closes #(issue_number)
Relates to #(issue_number)

## Changes Made

Please describe the specific changes made in this PR:

-
-
-

## Testing

- [ ] All existing tests pass (`./build.ps1 Test`)
- [ ] New tests added for new functionality
- [ ] Manual testing completed
- [ ] Code analysis passes (`./build.ps1 Analyze`)

## Documentation

- [ ] Function help documentation updated
- [ ] README updated (if applicable)
- [ ] CHANGELOG updated
- [ ] Function documentation added in `docs/functions/` (for new functions)

## Code Quality Checklist

- [ ] Code follows PowerShell best practices and OTBS style
- [ ] Self-review completed
- [ ] No breaking changes (or breaking changes are documented)
- [ ] Error handling implemented appropriately
- [ ] Input validation added where necessary
- [ ] Verbose/Debug output provided where helpful

## Function-Specific Checklist (for new functions)

- [ ] Function has complete help documentation with:
  - [ ] `.SYNOPSIS`
  - [ ] `.DESCRIPTION`
  - [ ] `.PARAMETER` (for each parameter)
  - [ ] `.EXAMPLE` (at least one realistic example)
  - [ ] `.NOTES` (with author and date)
- [ ] Function has corresponding Pester tests
- [ ] Function documentation added in `docs/functions/`
- [ ] Function follows module naming conventions
- [ ] Function is properly exported in module manifest

## Security Considerations

- [ ] No sensitive information exposed in code or comments
- [ ] Input sanitization implemented where needed
- [ ] File operations use secure practices
- [ ] No hardcoded credentials or paths

## Additional Notes

Please add any additional context, screenshots, or information that would help reviewers understand this PR.

## Reviewer Guidelines

- [ ] Code review completed
- [ ] Tests verified
- [ ] Documentation reviewed
- [ ] Security considerations evaluated
