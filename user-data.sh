#!/bin/bash
sudo apt-get update
sudo apt-get install software-properties-common -y
sudo apt-get-repository ppa:ansible/ansible -y
sudo apt-get update
sudo apt-get install ansible -y
sudo hostnamectl set-hostname ansible
