# Docker Installation and Configuration Script

## Description
This shell script automates the installation and configuration of Docker across multiple Linux distributions (Ubuntu, Alpine Linux, and Rocky Linux). It handles package installation, Docker daemon configuration, and user setup with Docker permissions.

## Features
- Cross-distribution compatibility (Ubuntu, Alpine Linux, Rocky Linux)
- Automated Docker installation and configuration
- User creation with Docker group permissions
- Configurable MTU settings
- Verbose mode for debugging
- Automatic verification using hello-world container

## Usage
```
./install.sh [OPTIONS] [USERNAMES...]

Options:
  --verbose, -v     Enable verbose output
  --mtu VALUE       Set custom MTU value (default: 1500)
```

## Examples
```
# Basic installation with default settings
./install.sh user1 user2

# Installation with verbose output
./install.sh --verbose user1 user2

# Installation with custom MTU
./install.sh --mtu 1400 user1 user2
```

## What the Script Does

1. **Argument Parsing**
   - Processes command-line arguments for verbose mode and MTU settings
   - Collects usernames for account creation

2. **Package Management**
   - Updates system packages
   - Installs Docker and required dependencies
   - Configures Docker repositories
   - Enables Docker service

3. **Docker Configuration**
   - Creates/updates daemon.json with specified MTU value
   - Configures debug mode based on verbose flag
   - Restarts Docker service with new settings

4. **User Management**
   - Creates specified user accounts
   - Adds users to Docker group
   - Sets default password as "ikt114"
   - Handles different user creation methods per distribution

5. **Verification**
   - Runs hello-world container to verify installation
   - Provides success message upon completion

## Requirements
- Root/sudo access
- One of the supported Linux distributions:
  - Ubuntu
  - Alpine Linux
  - Rocky Linux

## Notes
- Default MTU value is 1500
- Default user password is "ikt114"
- Script must be run with sudo privileges
