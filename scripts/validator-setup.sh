#!/bin/bash
novanet-cli init --validator --stake 5000 --name "NovaNet Validator"
novanet-cli start --validator
echo "Validator setup complete. Node is running."
