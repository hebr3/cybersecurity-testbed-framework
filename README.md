# Cybersecurity test bed framework

The repository contains a framework I designed for my Master Degree in Cybersecurity final project at CSUSM.

This framework is designed to make it easy for an instructor or student to quickly and consistently build a virtual network for use in a cybersecurity lab. The aim of this project was to make use of **Infastructure as Code** (IaC) techniques to automate most of the process of setting up lab environments. 

I believe that instructors will be more likely to implement and design hands on labs for students learning about cybersecurity when they have access to an easy method of building out a basic lab environment. By automating the respective tasks that are required to configure multiple virtual machines, professors should have more opportunities to focus on creating interesting labs.

This framework is also designed to automate much of the process of setting up and running individual labs. Under this framework labs are written as Ansible playbooks in utilizing yml syntax. Ansible was chosen because it is written in a highly human readable format and has idempotence as a primary goal.

The example labs provided with this framework utilize Ansible for the setup and provisioning of the virtual machines that are needed by the lab. A professor or student only needs to run ansible-playbook on the specific lab playbook to setup the respective lab.

This framework utilizes Proxmox as its default virtualization system. During my research for this project I found that Proxmox provided the best compatibility with the overall objectives of this project.

# Proxmox setup
Unfortunately there is no easy way to automate the setup of the base Proxmox system for use in this project. Instead the user will need to install Proxmox on their desired system manually. Official installation instructions can be found on the Proxmox [website](https://www.proxmox.com/en/proxmox-ve/get-started). I personally found this [video](https://www.youtube.com/watch?v=MO4CaHn1EjM&t=3s) by Jay LaCroix helpful in setting up Proxmox the first time.

Please note the password and ip address that you are assigning to this machine as they will be needed later in the setup process.

In this example I setup Proxmox with
> `IP ADDRESS = 192.168.0.90`

> `PASSWORD = csusm`

Once Proxmox has been installed on the system you will be asked to reboot the system. After the reboot you will be presented with a screen listing an https ip address that you can use to access the server.

From this point on we will by utilizing this web interface to interact with the system.

# Ansible setup

You can use the web shell provided by the Proxmox web interface or a seperate tool for the next steps. 

>I suggest you use a dedicated ssh client like mRemoteNG or Solar-PuTTY as I find them more responsive than the web interface for working within the shell.

You can download the setup script for the Ansible virtual machine with the following curl command.

> `curl -LJO https://raw.githubusercontent.com/hebr3/cybersecurity-testbed-framework/master/ansible_vm_setup/setup.sh`

You will want to change the GWADDR value to match the appropriate gateway address for your setup (This is likely your routers ip address). This code will download an LXC image for Ubuntu 18.04 and create an LXC virtual machine using this image. This virtual machine will then be updated and turned into a template that will be used to build other virtual machines in this project. 

The script will build an Ansible vm with username `ansible` and the password value added in the `ANSIBLEPASSWD` field in the script. 

```bash
#!/bin/bash
# Set these to target ip address for the ansible host and your network gateway ip address
GWADDR="192.168.0.1"
BASEIPADDR="192.168.0.99/24"
BASEPASSWD="csusm"
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
pct create 1000 /var/lib/vz/template/cache/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz -storage=local-lvm --hostname ubuntu1804 --password $BASSPASSWD
echo "Set network configuration for ubuntu vm"
pct set 1000 -net0 name=eth0,bridge=vmbr0,ip=$IPADDR,gw=$GWADDR
echo "Start vm"
pct start 1000
echo "Wait for startup"
sleep 10
echo "Update vm"
pct exec 1000 -- bash -c "apt update -y"
pct exec 1000 -- bash -c "apt upgrade -y"
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
echo "Install python on vm"
pct exec 210 -- bash -c "apt install python -y"
pct exec 210 -- bash -c "apt install pip -y"
pct exec 210 -- bash -c "apt update -y"
echo "Add Ansible user"
pct exec 210 -- bash -c "useradd ansible -s /bin/bash -m -g sudo -G sudo"
pct exec 210 -- bash -c "echo ansible:${ANSIBLEPASSWD} | chpasswd"
echo "Reboot pct"
pct stop 210
pct start 210
```

Run the following command to complete the setup of the Ansible and UbuntuTemplate virtual machines.

> `bash setup.sh`

The Proxmox web interface should now look like this.
![Web Interface should now look like this](https://github.com/hebr3/cybersecurity-testbed-framework/blob/master/ansible_vm_setup/Setup.PNG?raw=true)

We can now use the Ansible virtual machine and finish setup process.

# KVM Setup

Enter the Ansible vm with.

> `pct enter 210`
or
> `ssh ansible@192.168.0.210`

If you used `pct` you will need to switch to the ansible user with `su - ansible`.

We can now clone this repository into the Ansible virtual machine.

> `git clone https://github.com/hebr3/cybersecurity-testbed-framework.git`

Next move to the git folder

> cd cybersecurity-testbed-framework/lab_setup
