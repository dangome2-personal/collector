# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Git repository initialization
- Comprehensive test framework for expect scripts
- Unit tests for logging and string manipulation
- Integration tests for SSH session flow
- Test fixtures for device responses
- Documentation (README, TESTING, CONTRIBUTING)
- .gitignore for sensitive files

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.15] - 2025-08-01

### Added
- CURL Upload Function replacing SCP for uploading files to cxd.cisco.com
- Support for processing captured packets command
- Mechanism to copy tar file to /tmp/cisco/ in case of CURL timeout

### Changed
- CURL upload function now retries up to 3 times with delay between attempts
- Files deleted after successful upload to cxd.cisco.com
- Files deleted after unsuccessful upload to cxd.cisco.com

### Fixed
- Fixed SCP command handling for messages-LC files
- Added support for processing SCP commands for messages-LC files

---

## Version Guidelines

### Version Number Format: MAJOR.MINOR.PATCH

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards-compatible)
- **PATCH**: Bug fixes (backwards-compatible)

### Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security-related changes

### Example Entry

```markdown
## [1.1.0] - 2025-11-14

### Added
- Support for IOS-XE device collection (#45)
- New command timeout configuration option

### Fixed
- Admin mode exit handling (#52)
- File cleanup on CTRL+C interrupt
```
