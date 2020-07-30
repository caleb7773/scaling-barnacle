#!/bin/bash
sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
sudo apt install htop -y
sudo apt install tree -y
sudo apt install mlocate -y
sudo apt install cryptsetup -y
sudo apt install nmap -y
sudo apt install fail2ban -y
sudo apt install clamav clamav-daemon -y
sudo apt install chkrootkit rkhunter -y
sudo apt install apparmor apparmor-utils apparmor-profiles -y
##################################
#Disables IPv6 routing on the box#
##################################
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /g' /etc/default/grub
sudo update-grub
################################################
#Changes colors for Prompt and disables history#
################################################
echo 'export PS1="\[$(tput setaf 1)\]\u@\h:\w\$\[$(tput sgr0\] "' >> ~/.bashrc
echo "set +o history" >> ~/.bashrc
source ~/.bashrc
###############################
#Changes the SSH port to 20022#
###############################
sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config
sudo systemctl restart ssh
###############################
#Start CHKRootkit and RKHunter#
###############################
sudo chkrootkit
sudo rkhunter --check
#####################
#Enable IPv4 Routing#
#####################
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf && sudo sysctl -p

sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#
#
#Figure out how to edit the jail.local file with the following
#
#port = 20022
#enabled = true
#filter = sshd
#logpath = /var/log/auth.log
#maxretry = 3
#bantime = 120
#
#
sudo systemctl restart fail2ban
sudo systemctl restart ssh
#################################
#Starts Aide and builds database#
#################################
sudo apt install aide -y
sudo aideinit
sudo mv /var/lib/aide/aide.db.nw /var/lib/aide/aide.db
#########################
#Installs Lynis from GIT#
#########################
sudo apt install git -y
sudo su -
cd
git clone https://github.com/CISOfy/lynis.git
cd lynis/
./lynis audit system
###################################
#Displays all users who can log in#
###################################
echo 'Users who can log onto your machine:' >> /tmp/users
echo ' ' >> /tmp/users
cat /etc/passwd | grep 'bin/bash' | tee -a /tmp/users
echo ' ' >> /tmp/users
echo ' ' >> /tmp/users
########################################
#Displays all users who are SUDO admins#
########################################
echo 'Users who can SUDO on your machine:' >> /tmp/users
echo ' ' >> /tmp/users
cat /etc/group | grep 'sudo' | tee -a /tmp/users
clear
##################
#Restarts the box#
##################
cat /tmp/users
sudo reboot
