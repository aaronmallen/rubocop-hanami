# Security Policy

## Our Commitment

rubocop-hanami runs inside RuboCop against an application's source, often in CI with access to secrets. We take
security vulnerabilities seriously and will fix them promptly and in the open.

## What Constitutes a Security Vulnerability

A security vulnerability is an issue that could:

- Run code from the files a cop inspects
- Rewrite source during autocorrect in a way that opens a hole in the app
- Expose sensitive information in error messages or logs
- Allow unexpected behavior through improper input handling

**Not security vulnerabilities:**

- General bugs that don't compromise security
- Feature requests or enhancements
- Performance issues
- Documentation errors

## Reporting a Vulnerability

If you discover a security issue, please bring it to our attention right away!

### Reporting Process

Please **DO NOT** file a public issue. Instead, report security vulnerabilities through
[GitHub's private vulnerability reporting feature][vulnerability-report].

Your report should include:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Affected versions (if known)
- Suggested fix (if any)
- Your contact information for follow-up questions

### What to Expect

After you've submitted your report:

1. **Acknowledgment** - You'll receive confirmation within 24 hours
2. **Investigation** - We'll investigate and keep you updated on our findings
3. **Resolution** - Once we've determined the impact and developed a fix:

- We'll patch the vulnerability
- We'll coordinate disclosure timing with you
- We'll make an announcement to the community if warranted
- You'll be credited for the discovery (unless you prefer to remain anonymous)

### Response Timeline

- **24 hours** - Initial response acknowledging receipt
- **72 hours** - Preliminary assessment of impact and severity
- **7 days** - Detailed investigation results and remediation plan
- **30 days** - Target for patch release (may vary based on complexity)

## Disclosure Policy

We follow responsible disclosure practices:

1. **Confirm** the problem and determine affected versions
2. **Audit** code to find any similar problems
3. **Prepare** fixes for all supported versions
4. **Coordinate** with the reporter on disclosure timing
5. **Release** patches as soon as possible
6. **Publish** a security advisory with appropriate details

## Supported Versions

| Version | Support |
|:-------:|:-------:|
|  0.1.x  |   ✅    |

### Key

| Symbol | Meaning        |
|--------|----------------|
| ✅     | Supported      |
| ❌     | Not Supported  |
| 🧪     | Experimental   |
| 🚧     | In Development |

## Security Best Practices

When contributing to rubocop-hanami, please follow these security guidelines:

- Never commit sensitive data (API keys, tokens, passwords) to the repository
- Read the source a cop inspects through the AST, never by evaluating it
- Handle edge cases gracefully
- Keep dependencies up to date
- Use secure defaults in configuration

## Comments on this Policy

If you have suggestions on how this process could be improved, please submit a pull request or open an issue for
discussion.

## Contact

For urgent security matters that require immediate attention, you can also reach out to the maintainers directly
through GitHub.

[vulnerability-report]: https://github.com/aaronmallen/rubocop-hanami/security/advisories/new
