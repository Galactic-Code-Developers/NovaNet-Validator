#!/bin/bash
echo "Installing NovaNet Validator Node..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git cmake curl jq
git clone https://github.com/Galactic-Code-Developers/Blockchain-NovaNet-NOVA.git
cd Blockchain-NovaNet-NOVA
make build
sudo mv novanet-cli /usr/local/bin/
echo "Installation Complete. Use 'novanet-cli start --validator' to run your node."
