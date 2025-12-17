# Microsoft Collector - Network Automation Tool

## Overview

The Microsoft Collector (`msft_collector`) is an Expect-based automation tool designed to streamline data collection, diagnostics, and log management for Cisco network devices. It provides multiple operational modes to interact with IOS-XR (NCS-5500, Cisco 8000), and SONiC Network OS platforms.

**Version:** 1.0.23  
**Last Updated:** December 5, 2025

---

## Supported Platforms

- **IOS-XR Platforms:**
  - NCS-5500 Series (codename: fretta)
  - Cisco 8000 Series (codename: spitfire)
- **Network Operating Systems:**
  - SONiC Network OS

Platform detection is automatic based on `show version` output, enabling seamless multi-platform support.

---

## Project Structure

```
msft_collector/
├── msft_collector.exp              # Production script
├── msft_collector_lab.exp          # Lab/development script
├── msft_collector_deployment.sh    # Deployment and setup script
├── secret                          # Password file (gitignored)
├── fretta/                         # NCS-5500 playbooks
│   ├── *.playbook
│   └── *.showtech
├── spitfire/                       # Cisco 8000 playbooks
│   ├── *.playbook
│   └── *.showtech
├── sonic/                          # SONiC playbooks
│   ├── *.playbook
│   └── *.showtech
├── logs/                           # Command execution logs (gitignored)
├── showtechs/                      # Showtech file staging (gitignored)
└── tests/                          # Test directory
    ├── unit/                       # Unit tests for individual functions
    ├── integration/                # Integration tests with mock servers
    ├── fixtures/                   # Test data and mock responses
    └── run_tests.sh                # Test runner
```

---

## Key Features

### 🚀 Operational Modes

#### 1. **Interactive Mode** (`--interactive`)
Execute ad-hoc commands directly on devices with real-time interaction.

**Key Capabilities:**
- Single-host: Direct SSH execution without subprocess overhead
- Multi-host: Parallel execution on up to 50 devices simultaneously
- Interactive command collection with Ctrl+C support
- Exit options: `Ctrl+C`, `END`, or `exit` commands
- Automatic log compression and upload to Cisco File Server

**Use Cases:**
- Troubleshooting and diagnostic commands
- Quick data collection across multiple devices
- Custom command sequences without playbook creation

---

#### 2. **Playbook Mode** (`--playbook`)
Execute predefined command sequences from playbook files.

**Key Capabilities:**
- Platform-specific playbook directories (fretta/spitfire/sonic)
- Automatic platform detection and playbook selection
- Special handling for show logging with dynamic timestamps
- PPDB (Platform Database) collection from all line cards
- Messages-LC file retrieval from devices

**Use Cases:**
- Standardized data collection workflows
- Automated diagnostic procedures
- Multi-device configuration audits

**Special Feature - LC-FC Sequence:**
When `lc-fc.playbook` is detected, automatically triggers a 3-phase orchestrated sequence:
1. **Phase 1:** Execute playbook commands
2. **Phase 2:** Archive device logs
3. **Phase 3:** Collect showtech outputs

---

#### 3. **Showtech Mode** (`--showtech`)
Collect comprehensive technical support information from devices.

**Key Capabilities:**
- Platform-specific showtech commands
- Long-running command handling (20-minute timeout for SONiC)
- Background showtech monitoring for IOS-XR OS showtechs (Cisco 8000)
  - Automatic completion detection via log file polling
  - 100-minute timeout with graceful failure handling
  - Real-time elapsed time tracking
- Automatic file transfer to Cisco File Server
- Local file cleanup after successful upload

**Use Cases:**
- TAC case data collection
- Post-incident diagnostics
- Comprehensive device state capture

---

#### 4. **Archive-Log Mode** (`--archive-log`)
Archive and transfer device logs for historical analysis.

**Key Capabilities:**
- Automatic detection of archive-log configuration
- Dynamic year-based log collection
- Tar compression with verification
- SCP retry logic (3 attempts with 5-second delays)
- Empty directory handling (skips gracefully if no logs)
- Comprehensive error handling for connection failures

**Use Cases:**
- Periodic log archival
- Historical troubleshooting data collection
- Log file consolidation for analysis

---

#### 5. **Scan Mode** (`--scan`)
Execute playbooks across large device inventories in parallel.

**Key Capabilities:**
- Concurrent execution on up to 50 devices
- Hostname file support (one device per line)
- Aggregated log compression and upload
- Individual host ping checks before execution
- Subprocess isolation for fault tolerance

**Use Cases:**
- Fleet-wide data collection
- Bulk device diagnostics
- Network-wide configuration audits

---

#### 6. **List Playbooks** (`--list-playbooks`)
Display all available playbook and showtech files organized by platform directory.

---

### 🔧 Core Capabilities

#### Authentication & Connectivity
- Username from environment variable (`$USER`)
- Password from `secret` file in script directory
- SSH key auto-acceptance
- Custom SSH port support (hostname:port format)
- Automatic reachability checks (ping before connect)

#### File Management
- CURL-based uploads to cxd.cisco.com (replacing SCP)
- 60-minute timeout for large files (50MB+ showtechs)
- Retry logic (3 attempts with delays)
- Automatic local cleanup after successful uploads
- Backup to `/tmp/cisco/` on upload failures

#### Command Execution
- Smart prompt pattern matching (IOS-XR, SONiC, Nexus)
- Command echo consumption to prevent premature matching
- Sudo password prompt handling
- Long-running command support (20-minute timeouts)
- Background process monitoring (OS showtechs)

#### Platform Detection
- Automatic platform identification via `show version`
- Conditional command execution based on platform
- Platform-specific playbook directory selection
- SONiC-specific long command handlers

#### Logging

- Timestamped log files: `hostname_YYYYMMDD_HHMMSS.log`
- Scan mode: Simple naming (`hostname.log`)
- Log start/end timestamps
- Execution duration tracking

---

## Requirements

- **Expect:** Installed and available in PATH
- **SSH:** Client configured for password authentication
- **SCP:** For file transfers from devices
- **CURL:** For uploads to cxd.cisco.com
- **Bash:** For subprocess execution in scan mode
- **Network:** Connectivity to target devices and cxd.cisco.com

---

## Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd msft_collector
   ```

2. Create a password file:

   ```bash
   echo "your_password" > secret
   chmod 600 secret
   ```

3. Make the scripts executable:

   ```bash
   chmod +x msft_collector.exp msft_collector_lab.exp
   ```

## Usage

### Basic Modes

#### List Available Playbooks

```bash
./msft_collector.exp --list-playbooks
```

### Usage Examples

**Interactive Mode:**

```bash
# Single device
./msft_collector.exp --interactive router1.example.com SR123456 <token>

# Multiple devices
./msft_collector.exp --interactive hostnames.txt SR123456 <token>
```

**Playbook Mode:**

```bash
# Execute playbook on single device
./msft_collector.exp --playbook healthcheck.playbook router1.example.com SR123456 <token>

# Execute on multiple devices
./msft_collector.exp --playbook healthcheck.playbook hostnames.txt SR123456 <token>

# LC-FC auto-sequence (playbook → archive-log → showtech)
./msft_collector.exp --playbook lc-fc.playbook router1.example.com SR123456 <token>
```

**Showtech Mode:**

```bash
# Collect showtech from single device
./msft_collector.exp --showtech generic.showtech router1.example.com SR123456 <token>

# Multiple devices
./msft_collector.exp --showtech generic.showtech hostnames.txt SR123456 <token>
```

**Archive-Log Mode:**

```bash
# Archive logs from single device
./msft_collector.exp --archive-log router1.example.com SR123456 <token>

# Multiple devices
./msft_collector.exp --archive-log hostnames.txt SR123456 <token>
```

**Scan Mode:**

```bash
# Scan 50 devices concurrently
./msft_collector.exp --scan hostnames.txt healthcheck.playbook SR123456 <token>
```

---

## Special Features

### PPDB Collection

Automated Platform Database (PPDB) collection from all line cards:

1. Detects `pd_aib_show_prod` command in playbook
2. Identifies all active line cards via `show platform`
3. Attaches to each LC and executes PPDB dump
4. Transfers files to active RP
5. Compresses all LC dumps into timestamped tarball
6. Uploads consolidated tarball to Cisco File Server

**Used By:** Playbook mode, Scan mode

### LC-FC Automated Sequence

Three-phase orchestration for Line Card/Fabric Card diagnostics:

1. **Playbook Execution:** Run diagnostic commands
2. **Log Archival:** Collect and compress device logs
3. **Showtech Collection:** Capture comprehensive tech-support data

**Triggered By:** Using `lc-fc.playbook` in playbook mode  
**Prevent Recursion:** `--no-lc-fc-detection` flag

### OS Showtech Background Monitoring

For Cisco 8000 (Spitfire) platform:

1. Detects `show tech-support os file harddisk: background compressed`
2. Transforms to timestamped background command
3. Polls log file every 60 seconds for completion marker
4. 100-minute timeout with graceful skip
5. Displays real-time elapsed time
6. Auto-transfers TGZ file after completion

**Used By:** Showtech mode (Cisco 8000 only)

### Custom SSH Port Support

Format: `hostname:port`

```bash
./msft_collector.exp --interactive router1.example.com:2222 SR123456 <token>
```

Applies to SSH connections and SCP file transfers.

**Used By:** All modes

---

## Authentication Setup

1. Create `secret` file in script directory:

   ```bash
   echo "your_password_here" > secret
   chmod 600 secret
   ```

2. Ensure `$USER` environment variable is set (automatic in most shells)

### Credential Flow

- **Username:** `$USER` environment variable
- **Password:** Content of `secret` file
- **CXD Token:** Provided as command-line argument

---

## File Transfer & Cleanup

### Upload Process

1. Command execution logs saved to `logs/` directory
2. Logs compressed into timestamped tarball
3. CURL upload to cxd.cisco.com (60-minute timeout)
4. Retry logic: 3 attempts with 10-second delays
5. On success: Local files deleted
6. On failure: Tarball copied to `/tmp/cisco/` for backup

### Supported File Types

- `.log` - Command execution logs
- `.capture-packets-traps` - Packet capture files
- `messages-LC*` - Line card syslog files
- `ppdb_prod_dump_all_lcs_*.tar.gz` - PPDB tarballs
- `showtech-*.tgz` - Showtech archives

---

## Version History

**1.0.23** (December 5, 2025)

- Enhanced LC-FC sequence orchestration
- Added OS showtech background monitoring
- Improved prompt pattern matching for Nexus devices
- Fixed archive-log empty directory handling
- Added --no-lc-fc-detection flag for recursion prevention

---

## Troubleshooting

### Debug Mode

Set `log_user 1` in script to enable verbose output to terminal.

### Common Issues

- **Connection timeout:** Check network connectivity and SSH port
- **Authentication failure:** Verify `secret` file and `$USER` variable
- **Platform detection fail:** Check `show version` output format
- **Showtech timeout:** Normal for large showtechs (up to 100 minutes)

### Log Files

All execution logs saved to `logs/` directory with timestamps for post-execution analysis.

---

## Best Practices

1. **Test playbooks** in lab environment before production use
2. **Use scan mode** for large-scale operations (parallelization)
3. **Monitor disk space** on cxd.cisco.com for large showtechs
4. **Verify hostname files** have one device per line (Unix line endings)
5. **Use custom SSH ports** when standard port 22 is not available
6. **Review logs** after execution for error patterns
7. **Clean up local files** if transfer failures occur

---

## Security Notes

- Never commit the `secret` file to version control
- Restrict permissions on secret file: `chmod 600 secret`
- Logs may contain sensitive information - review before sharing
- Clear old log files regularly

---

## License

Cisco Internal Use Only.

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

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Write tests for new functionality
3. Ensure all tests pass: `./tests/run_tests.sh`
4. Commit your changes: `git commit -am 'Add new feature'`
5. Push to the branch: `git push origin feature/your-feature`
6. Submit a pull request

---

## Contact

[Your contact information]

## Acknowledgments

- Built for Microsoft Azure network operations
- Supports Cisco IOS XR and SONiC platforms
