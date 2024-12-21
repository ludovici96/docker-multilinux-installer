#!/bin/bash

# Parses command-line options to set script behavior
parse_args() {
    VERBOSE=false
    MTU_VALUE=1500  # Sets a default MTU value
    local next_arg_is_mtu=false

    # Initialize USERS array
    USERS=()

    for arg in "$@"; do
        if $next_arg_is_mtu; then
            MTU_VALUE=$arg
            next_arg_is_mtu=false
            continue
        fi
        case $arg in
            --verbose|-v)
                VERBOSE=true
                ;;
            --mtu)
                next_arg_is_mtu=true
                ;;
            *)
                USERS+=("$arg")
                ;;
        esac
    done
}

# Updates and installs required packages based on OS
update_and_install_packages() {
    if $VERBOSE; then
        set -x  # Enable command tracing
    else
        exec 3>&1 >/dev/null 2>&1  # Redirect output to suppress non-verbose output
    fi

    # Check OS and install Docker accordingly
    if grep -q "Ubuntu" /etc/os-release; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get install -y docker-ce docker-compose-plugin
        sudo systemctl enable docker
        sudo systemctl stop docker
    elif grep -q "Alpine Linux" /etc/os-release; then
        sudo apk update
        sudo apk add docker docker-compose
        sudo rc-update add docker boot
        sudo rc-service docker stop
    elif grep -q "Rocky Linux" /etc/os-release; then
        sudo dnf check-update
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-compose-plugin
        sudo systemctl enable docker
        sudo systemctl stop docker
    else
        echo "Unsupported OS"
        exit 1
    fi

    # Disable tracing or restore output redirection based on verbosity
    if $VERBOSE; then
        set +x
    else
        exec 1>&3 3>&-
    fi
}

# Configures Docker daemon settings
configure_docker() {
    # Create or update daemon.json with MTU and debug settings
    if [ ! -f /etc/docker/daemon.json ]; then
        sudo mkdir -p /etc/docker
        echo "{\"mtu\": $MTU_VALUE, \"debug\": $VERBOSE}" | sudo tee /etc/docker/daemon.json
    else
        echo "{\"mtu\": $MTU_VALUE, \"debug\": $VERBOSE}" | sudo tee /etc/docker/daemon.json
    fi

    # Restart Docker depending on the OS
    if grep -q "Ubuntu" /etc/os-release || grep -q "Rocky Linux" /etc/os-release; then
        sudo systemctl start docker
    elif grep -q "Alpine Linux" /etc/os-release; then
        sudo rc-service docker restart
    fi
    
        # Restart Docker depending on the OS
    if grep -q "Ubuntu" /etc/os-release || grep -q "Rocky Linux" /etc/os-release; then
        sudo systemctl start docker
        sleep 5  # Shorter sleep for systems using systemd
    elif grep -q "Alpine Linux" /etc/os-release; then
        sudo rc-service docker restart
        sleep 20  # Longer sleep for Alpine Linux, as needed
    fi

    #run hello-world docker image to check docker works.
    sudo docker run hello-world
}

# Creates users and sets their passwords
create_users() {
    if grep -q "Alpine Linux" /etc/os-release; then
        # Alpine Linux uses adduser and chpasswd
        for user in "${USERS[@]}"; do
            sudo adduser -D -G docker "$user"
            # Use echo to directly pipe the password to chpasswd with the username
            echo "$user:ikt114" | sudo chpasswd
        done
    else
        # Ubuntu and Rocky Linux use useradd and usermod
        for user in "${USERS[@]}"; do
            sudo useradd -m -G docker "$user"
            # Create the hash password and apply it
            hashed_password=$(openssl passwd -1 "ikt114")
            sudo usermod -p "$hashed_password" "$user"
        done
    fi
}

# Main execution flow of the script
parse_args "$@"
update_and_install_packages
configure_docker
create_users

# Final script completion message
echo -e "\033[32mFinished with everything.\033[0m"