# Testing Guide for MSFT Collector

## Overview

This testing framework provides comprehensive test coverage for expect scripts using a combination of unit tests, integration tests, and fixture-based validation.

## Test Structure

```
tests/
├── unit/                   # Unit tests for individual procedures
├── integration/            # End-to-end tests with mock servers
├── fixtures/               # Test data and mock device responses
├── lib/                    # Shared testing utilities
│   ├── test_framework.exp # Core testing functions
│   └── mock_server.exp    # Mock SSH server for testing
├── run_tests.sh           # Main test runner
└── README.md              # This file
```

## Running Tests

### Run All Tests
```bash
./run_tests.sh
```

### Run Specific Test Suite
```bash
./run_tests.sh unit          # Run only unit tests
./run_tests.sh integration   # Run only integration tests
```

### Run Individual Test
```bash
expect tests/unit/test_logging.exp
```

## Writing Tests

### Unit Test Example

Create a file in `tests/unit/` following this pattern:

```tcl
#!/usr/bin/expect

# Source the test framework
source [file join [file dirname [info script]] "../lib/test_framework.exp"]

# Initialize test suite
test_suite_start "Logging Functions"

# Test case 1
test_case "initialize_logging creates log file" {
    # Setup
    set hostname "test-device"
    
    # Execute
    initialize_logging $hostname
    
    # Assert
    assert_file_exists $log_file
    assert_match $log_file "*test-device*"
}

# Test case 2
test_case "initialize_logging reads password file" {
    # Setup
    set ::env(USER) "testuser"
    
    # Execute
    initialize_logging "test"
    
    # Assert
    assert_not_empty $password
}

# Finish test suite
test_suite_end
```

### Integration Test Example

Create a file in `tests/integration/` for end-to-end scenarios:

```tcl
#!/usr/bin/expect

source [file join [file dirname [info script]] "../lib/test_framework.exp"]
source [file join [file dirname [info script]] "../lib/mock_server.exp"]

test_suite_start "SSH Connection and Commands"

test_case "connects to device and executes command" {
    # Start mock SSH server
    set server_pid [start_mock_server 2222]
    
    # Execute
    spawn ssh -p 2222 localhost
    expect "password:"
    send "testpass\r"
    expect "#"
    send "show version\r"
    expect "#"
    
    # Assert
    assert_output_contains "Mock IOS XR Version"
    
    # Cleanup
    stop_mock_server $server_pid
}

test_suite_end
```

## Test Framework Functions

### Assertion Functions

- `assert_true <condition>` - Assert condition is true
- `assert_false <condition>` - Assert condition is false
- `assert_equal <actual> <expected>` - Assert values are equal
- `assert_not_equal <actual> <expected>` - Assert values are different
- `assert_match <string> <pattern>` - Assert string matches pattern
- `assert_contains <haystack> <needle>` - Assert string contains substring
- `assert_file_exists <filepath>` - Assert file exists
- `assert_file_contains <filepath> <text>` - Assert file contains text
- `assert_output_contains <text>` - Assert expect output contains text
- `assert_not_empty <value>` - Assert value is not empty

### Test Organization Functions

- `test_suite_start <name>` - Begin a test suite
- `test_suite_end` - End test suite and print summary
- `test_case <name> <body>` - Define a test case
- `setup` - Run before each test (override this)
- `teardown` - Run after each test (override this)

### Mock Server Functions

- `start_mock_server <port>` - Start a mock SSH server
- `stop_mock_server <pid>` - Stop a running mock server
- `add_mock_response <pattern> <response>` - Define expected interactions
- `verify_mock_calls` - Verify all expected calls were made

## Test Fixtures

Place test data in `tests/fixtures/`:

- `device_responses/` - Mock device command outputs
- `test_configs/` - Sample configuration files
- `expected_outputs/` - Known-good outputs for comparison

### Using Fixtures

```tcl
proc load_fixture {name} {
    set fixture_path [file join [file dirname [info script]] "../fixtures" $name]
    set fp [open $fixture_path r]
    set data [read $fp]
    close $fp
    return $data
}

test_case "parses show version output" {
    set output [load_fixture "device_responses/show_version_xr.txt"]
    set version [parse_version $output]
    assert_equal $version "7.3.1"
}
```

## Continuous Integration

Tests are designed to run in CI/CD pipelines:

```bash
#!/bin/bash
# .github/workflows/test.yml or similar

# Install dependencies
apt-get install -y expect

# Run tests
cd tests
./run_tests.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "All tests passed!"
else
    echo "Tests failed!"
    exit 1
fi
```

## Test Coverage

Track which functions/procedures are tested:

```bash
# List all procedures in main scripts
grep -E "^proc " ../msft_collector.exp

# Ensure each has corresponding test
```

## Best Practices

1. **Test Independence**: Each test should be self-contained
2. **Clear Names**: Test names should describe what is being tested
3. **Setup/Teardown**: Clean up after tests (files, processes)
4. **Mock External Dependencies**: Don't rely on real devices in tests
5. **Fast Tests**: Unit tests should run in milliseconds
6. **Comprehensive**: Test both success and failure paths

## Debugging Failed Tests

### Verbose Mode
```bash
./run_tests.sh -v
```

### Run Single Test with Debug
```bash
expect -d tests/unit/test_logging.exp
```

### Check Test Logs
```bash
cat test_logs/latest.log
```

## Troubleshooting

### "spawn: command not found"
- Install expect: `brew install expect` (macOS) or `apt-get install expect` (Linux)

### "Permission denied" on test files
- Make tests executable: `chmod +x tests/**/*.exp tests/run_tests.sh`

### Mock server won't start
- Check if port is in use: `lsof -i :2222`
- Use different port in tests

## Contributing Tests

When adding new features:

1. Write tests first (TDD approach)
2. Ensure tests pass before committing
3. Add integration tests for critical paths
4. Update this README if adding new test patterns
