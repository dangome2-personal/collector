# Contributing to MSFT Collector

Thank you for your interest in contributing! This document provides guidelines and best practices.

## Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/msft_collector.git
   cd msft_collector
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Install Dependencies**
   ```bash
   # macOS
   brew install expect
   
   # Ubuntu/Debian
   sudo apt-get install expect
   ```

## Development Workflow

### 1. Make Changes

- Follow existing code style
- Add comments for complex logic
- Update documentation if needed

### 2. Write Tests

**Always write tests for new features:**

```bash
# Create test file
touch tests/unit/test_your_feature.exp
chmod +x tests/unit/test_your_feature.exp
```

### 3. Run Tests

```bash
cd tests
./run_tests.sh
```

All tests must pass before submitting a pull request.

### 4. Update Documentation

- Update README.md if adding user-facing features
- Update TESTING.md if adding new test patterns
- Add inline comments for complex code

### 5. Commit Changes

Follow conventional commit format:

```bash
git commit -m "type: brief description

Detailed explanation of what and why.

- List specific changes
- Reference issue numbers (#123)
"
```

**Commit Types:**
- `feat:` New feature
- `fix:` Bug fix
- `test:` Adding or updating tests
- `docs:` Documentation changes
- `refactor:` Code restructuring
- `chore:` Maintenance tasks

**Examples:**
```bash
git commit -m "feat: add support for IOS-XE devices"
git commit -m "fix: correct timeout handling in CURL upload"
git commit -m "test: add integration tests for admin mode"
git commit -m "docs: update README with new usage examples"
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Code Style Guidelines

### Expect/Tcl Scripts

1. **Indentation**: 4 spaces (no tabs)
2. **Braces**: Opening brace on same line
3. **Procedures**: 
   ```tcl
   proc my_procedure {param1 param2} {
       # Body
   }
   ```

4. **Global Variables**: Declare at top of procedure
   ```tcl
   proc my_proc {} {
       global my_var
       set my_var "value"
   }
   ```

5. **Comments**: 
   ```tcl
   # Single line comment
   
   # Multi-line explanation
   # continues here
   proc documented_function {arg} {
       # ...
   }
   ```

### Bash Scripts

1. **Indentation**: 2 or 4 spaces
2. **Quotes**: Use double quotes for variables
3. **Error Handling**: Use `set -e` and check return codes
4. **Functions**:
   ```bash
   function_name() {
       local var="value"
       # Body
   }
   ```

## Testing Requirements

### Test Coverage

- All new functions must have unit tests
- Critical workflows need integration tests
- Aim for >80% code coverage

### Test Quality

- Tests must be deterministic (no random failures)
- Use mocks for external dependencies
- Tests should run in <5 seconds
- Include both success and failure cases

### Example Test Structure

```tcl
#!/usr/bin/expect
source [file join [file dirname [info script]] "../lib/test_framework.exp"]

test_suite_start "Feature Name"

proc setup {} {
    # Pre-test setup
}

proc teardown {} {
    # Post-test cleanup
}

test_case "normal operation" {
    # Test happy path
}

test_case "error handling" {
    # Test error cases
}

test_suite_end
```

## Pull Request Process

### Before Submitting

- [ ] All tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] No sensitive data in commits

### PR Description

Include:
1. **What**: What does this PR do?
2. **Why**: Why is this change needed?
3. **How**: How was it implemented?
4. **Testing**: What tests were added/modified?
5. **Screenshots**: If applicable

**Example:**
```markdown
## What
Adds support for IOS-XE device collection

## Why
Customers are requesting support for IOS-XE platforms

## How
- Added device detection logic
- Modified command execution to handle IOS-XE prompts
- Added IOS-XE specific commands

## Testing
- Added unit tests for device detection
- Added integration test with mock IOS-XE device
- Tested manually on real IOS-XE device

## Related Issues
Closes #123
```

### Review Process

1. Automated tests will run
2. Maintainer will review code
3. Address feedback if any
4. Once approved, PR will be merged

## Issue Reporting

### Bug Reports

Include:
- Expected behavior
- Actual behavior
- Steps to reproduce
- Environment (OS, expect version)
- Relevant logs

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Willingness to implement

## Security

- Never commit passwords or secrets
- Check `.gitignore` before committing
- Report security issues privately
- Use secure coding practices

## Questions?

- Check documentation first
- Search existing issues
- Ask in discussions
- Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the project's license.

Thank you for contributing! 🎉
