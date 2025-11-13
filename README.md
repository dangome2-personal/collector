# MSFT Collector

Automated data collection scripts for Microsoft Azure Cisco network devices using Expect and Bash.

## Overview

This project contains automated scripts for connecting to Cisco network devices in Microsoft Azure environments (Phoenix data centers) and collecting various diagnostic data including show tech, logs, and packet captures. The collected data is uploaded to cxd.cisco.com for analysis.

## Project Structure

```
msft_collector/
├── msft_collector.exp         # Production expect script
├── msft_collector_lab.exp     # Lab/testing expect script
├── msft_collector_deployment.sh  # Deployment and setup script
├── tests/                     # Test directory
│   ├── unit/                  # Unit tests for individual functions
│   ├── integration/           # Integration tests with mock servers
│   ├── fixtures/              # Test data and mock responses
│   └── run_tests.sh          # Test runner
├── logs/                      # Script execution logs (gitignored)
├── showtechs/                 # Collected showtech files (gitignored)
└── secret                     # Password file (gitignored)
```

## Features

- Automated SSH connection to Cisco devices
- Support for both IOS XR and SONiC platforms
- CURL-based file upload to cxd.cisco.com with retry mechanism
- Comprehensive logging of all operations
- Handles admin mode transitions
- Processes captured packets and message-LC files
- Automatic cleanup of uploaded files

## Requirements

- `expect` - For automation of interactive applications
- `bash` - Shell scripting
- `curl` - For file uploads
- SSH access to target devices
- Valid credentials for device authentication

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd msft_collector
   ```

2. Run the deployment script to set up directories and credentials:
   ```bash
   ./msft_collector_deployment.sh
   ```

3. The script will prompt for your password, which will be securely stored in the `secret` file.

## Usage

### Running the Production Script

```bash
./msft_collector.exp <hostname>
```

Example:
```bash
./msft_collector.exp PHX10-0100-0100-01RHE
```

### Running the Lab Script

```bash
./msft_collector_lab.exp <hostname>
```

### Batch Processing

The deployment script creates hostname lists for different device types:
- `XR-PHX-CRI-hostname-list` - IOS XR devices
- `SONIC-PHX-CRI-hostname-list` - SONiC devices

You can loop through these lists:
```bash
while read hostname; do
    ./msft_collector.exp "$hostname"
done < XR-PHX-CRI-hostname-list
```

## Testing

### Running Tests

Execute all tests:
```bash
cd tests
./run_tests.sh
```

Run specific test suites:
```bash
./run_tests.sh unit
./run_tests.sh integration
```

### Test Types

1. **Unit Tests**: Test individual expect procedures in isolation
2. **Integration Tests**: Test full workflows with mock SSH servers
3. **Fixture Tests**: Validate against known-good device responses

See [Testing Guide](tests/README.md) for detailed information on writing and running tests.

## Configuration

### Timeout Settings

Default timeout is set in the expect scripts. Adjust as needed for slower connections.

### Log File Location

Logs are stored in `logs/` directory with format: `{hostname}_{timestamp}.log`

### Upload Retry Configuration

The CURL upload function retries up to 3 times with delays between attempts.

## Security Notes

- Never commit the `secret` file to version control
- Restrict permissions on the secret file (600)
- Logs may contain sensitive information - review before sharing
- Clear old log files regularly

## Version History

### Version 1.0.15 (August 1, 2025)
- CURL Upload Function replacing SCP
- Fixed SCP command handling for messages-LC files
- Added support for processing captured packets command
- CURL upload function retries up to 3 times
- Files deleted after successful/unsuccessful upload
- Mechanism to copy tar file to /tmp/cisco/ on CURL timeout

## Troubleshooting

### Connection Issues
- Verify SSH connectivity: `ssh <hostname>`
- Check credentials in the `secret` file
- Ensure firewall allows SSH connections

### Upload Failures
- Check network connectivity to cxd.cisco.com
- Verify CURL is installed and accessible
- Review logs for specific error messages

### Script Hangs
- Increase timeout values
- Check device responsiveness
- Review expect patterns in the script

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Write tests for new functionality
3. Ensure all tests pass: `./tests/run_tests.sh`
4. Commit your changes: `git commit -am 'Add new feature'`
5. Push to the branch: `git push origin feature/your-feature`
6. Submit a pull request

## License

[Specify your license here]

## Contact

[Your contact information]

## Acknowledgments

- Built for Microsoft Azure network operations
- Supports Cisco IOS XR and SONiC platforms
