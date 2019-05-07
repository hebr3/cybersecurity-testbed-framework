#!/bin/bash
# Set these to target ip address for the ansible host and your network gateway ip address
GWADDR="192.168.0.1"
IPADDR="192.168.0.99/24"
ANSIBLEADDR="192.168.0.210/24"
ANSIBLEPASSWD="csusm"
echo  "Update and Upgrade the Proxmox distribution"
apt update -y
apt upgrade -y
echo "Update pveam"
#pveam update
echo "Download LXC Ubuntu image"
pveam download local ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz
echo "Build LXC virtual machine"
pct create 1000 /var/lib/vz/template/cache/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz -storage=local-lvm --hostname ubuntu1804 --password csusm
echo "Set network configuration for ubuntu vm"
pct set 1000 -net0 name=eth0,bridge=vmbr0,ip=$IPADDR,gw=$GWADDR
echo "Start vm"
pct start 1000
echo "Wait for startup"
sleep 10
echo "Update vm"
pct exec 1000 -- bash -c "apt update -y"
pct exec 1000 -- bash -c "apt upgrade -y"
echo "Install python on vm"
pct exec 1000 -- bash -c "apt install python -y"
echo "Convert updated vm to template"
pct stop 1000
pct template 1000
sleep 10
echo "Create Ansible vm"
pct clone 1000 210 --hostname ansible --storage=local-lvm --full
echo "Set network configuration for Ansible vm"
pct set 210 -net0 name=eth0,bridge=vmbr0,ip=$ANSIBLEADDR,gw=$GWADDR
echo "Start Ansible vm"
pct start 210
sleep 10
echo "Install Ansible on vm"
pct exec 210 -- bash -c "apt install ansible -y"
echo "Install git on vm"
pct exec 210 -- bash -c "apt install git -y"
pct exec 210 -- bash -c "apt update -y"
echo "Add sshpass"
pct exec 210 -- bash -c "apt install sshpass"
echo "Add Ansible user"
pct exec 210 -- bash -c "useradd ansible -s /bin/bash -m -g sudo -G sudo"
pct exec 210 -- bash -c "echo ansible:${ANSIBLEPASSWD} | chpasswd"
echo "Reboot pct"
pct stop 210
pct start 210