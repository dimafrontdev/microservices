#!/bin/bash

echo "=== Installing all instruments ==="

if ! command -v docker &> /dev/null

then
    echo "Docker not found. Installing Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed."
fi

if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

if ! python3 --version | grep -q "3\.[9-9]\|3\.[1-9][0-9]"; then
    echo "Python 3.9+ not found. Installing Python 3.9..."
    sudo apt update
    sudo apt install -y python3.9 python3.9-venv python3.9-dev
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
    sudo apt install -y python3-pip
else
    echo "Python 3.9+ is already installed."
fi

if ! python3 -m django --version &> /dev/null
then
    echo "Django not found. Installing Django..."
    pip3 install django
else
    echo "Django is already installed."
fi

echo "=== Installation completed! ==="
