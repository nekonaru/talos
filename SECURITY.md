# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Reporting a Vulnerability

Report vulnerabilities privately through [GitHub Security Advisories](https://github.com/nekonaru/talos/security/advisories/new).

If you cannot use advisories, open a regular issue without technical details and ask for a private contact. Do not post exploitation steps publicly before the fix is released.

Please include:

- What you did
- What happened
- What you expected to happen
- Version, platform and device or OS

## Scope

Talos downloads files from third-party sites at the user's request. Reports most useful to us:

- Crashes and hangs triggered by app input (URL, command template, filename)
- Unsafe file handling (path traversal, unexpected overwrite, deletion of user files)
- Network security issues in the download engine or update mechanism
- Exposure of private data stored by the app

Out of scope: issues in yt-dlp itself (report upstream), issues in third-party sites, and phishing or spam behavior of downloaded content.

We will confirm receipt, investigate, and publish a fix or a clear explanation of why the behavior is expected. We do not offer bounties.
