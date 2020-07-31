#!/bin/bash
ssh_port() {
  read -p "SSH Port: " ssh_port_num
}
ssh_port
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
sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /g' /etc/default/grub
sudo update-grub
################################################
#Changes colors for Prompt and disables history#
################################################
echo 'export PS1="\[$(tput setaf 4; tput bold; tput rev)\]\u@\h:\w\$\[$(tput sgr0\] "' >> ~/.bashrc
echo "set +o history" >> ~/.bashrc
source ~/.bashrc
###############################
#Changes the SSH port to 20022#
###############################
sudo sed -i "s/#Port 22/Port ${ssh_port_num}/g" /etc/ssh/sshd_config
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
###########################################
#Setting up Fail2ban for SSH on port 20022#
###########################################
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#############################################################
#Removing the existing SSH commands from the jail.local file#
#############################################################
sudo sed -i 's/^\[sshd\]//g' /etc/fail2ban/jail.local
sudo sed -i 's/^port    = ssh//g' /etc/fail2ban/jail.local
sudo sed -i 's/^logpath = %(sshd_log)s//g' /etc/fail2ban/jail.local
sudo sed -i 's/^backend = %(sshd_backend)s//g' /etc/fail2ban/jail.local
##################################################
#Appending the new SSH config into the jail.local#
##################################################
sudo tee -a /etc/fail2ban/jail.local <<EOF

[sshd]
port = ${ssh_port_num}
enabled = true
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 120
EOF
#############################
#Restarting Fail2Ban and SSH#
#############################
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
