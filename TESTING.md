# Testing Quick Reference

## Running Tests

```bash
# Run all tests
cd tests && ./run_tests.sh

# Run only unit tests
./run_tests.sh unit

# Run only integration tests
./run_tests.sh integration

# Run a single test file
expect tests/unit/test_logging.exp
```

## Creating a New Test

1. **Unit Test** (in `tests/unit/`):

```tcl
#!/usr/bin/expect
source [file join [file dirname [info script]] "../lib/test_framework.exp"]

test_suite_start "My New Feature"

test_case "describe what it tests" {
    # Arrange
    set input "test data"
    
    # Act
    set result [my_function $input]
    
    # Assert
    assert_equal $result "expected output"
}

test_suite_end
```

2. **Integration Test** (in `tests/integration/`):

```tcl
#!/usr/bin/expect
source [file join [file dirname [info script]] "../lib/test_framework.exp"]

test_suite_start "End-to-End Workflow"

proc setup {} {
    # Create test resources
}

proc teardown {} {
    # Clean up test resources
}

test_case "full workflow test" {
    # Test complete user flow
}

test_suite_end
```

3. Make test executable:

```bash
chmod +x tests/unit/my_test.exp
```

## Common Assertions

```tcl
assert_true <condition>
assert_false <condition>
assert_equal <actual> <expected>
assert_not_equal <actual> <unexpected>
assert_match <string> <glob_pattern>
assert_contains <haystack> <needle>
assert_not_empty <value>
assert_file_exists <filepath>
assert_file_contains <filepath> <text>
```

## Helper Functions

```tcl
# Create temporary file
set temp_file [create_temp_file "file content"]
cleanup_temp_file $temp_file

# Create temporary directory
set temp_dir [create_temp_dir]
cleanup_temp_dir $temp_dir
```

## Test Fixtures

Place test data in `tests/fixtures/`:

```tcl
proc load_fixture {name} {
    set fixture_path [file join [file dirname [info script]] "../fixtures" $name]
    set fp [open $fixture_path r]
    set data [read $fp]
    close $fp
    return $data
}

# Usage
set mock_output [load_fixture "device_responses/show_version_xr.txt"]
```

## Debugging

```bash
# Run with expect debugger
expect -d tests/unit/test_logging.exp

# Check test logs
cat test_logs/latest.log

# Verbose expect output
expect -c "log_user 1; source tests/unit/test_logging.exp"
```

## Best Practices

1. **One concept per test** - Each test should verify one specific behavior
2. **Descriptive names** - Test names should explain what they test
3. **AAA Pattern** - Arrange, Act, Assert structure
4. **Independent tests** - Tests shouldn't depend on each other
5. **Clean up** - Use teardown to remove temporary files/processes
6. **Fast tests** - Mock external dependencies, avoid slow operations

## Example: Testing a Function

```tcl
# Function to test (from main script)
proc format_hostname {full_name} {
    return [string toupper [lindex [split $full_name "."] 0]]
}

# Test
test_case "formats hostname correctly" {
    set result [format_hostname "device.example.com"]
    assert_equal $result "DEVICE"
}
```

## CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install expect
        run: sudo apt-get install -y expect
      - name: Run tests
        run: cd tests && ./run_tests.sh
```
