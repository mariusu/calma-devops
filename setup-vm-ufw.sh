#!/bin/bash
#### Setup script for a virtual machine

# Setup local firewall using UFW (Uncomplicated Firewall)
sudo apt update
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
sudo ufw status verbose

