#!/bin/bash
sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
sudo apt install htop -y
sudo apt install tree -y
sudo apt install mlocate -y
sudo apt install cryptsetup -y
sudo apt install nmap -y
sudo apt install fail2ban -y

sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /g'
sudo update-grub

echo 'export PS1="\[$(tput setaf 1)\]\u@\h:\w\$\[$(tput sgr0\] "' >> ~/.bashrc
source ~/.bashrc

sudo sed -i 's/Port 22/Port 20022/g' /etc/ssh/sshd_config
sudo systemctl restart ssh

sudo apt install clamav clamav-daemon -y
sudo apt install chkrootkit rkhunter -y
sudo apt install apparmor apparmor-utils apparmor-profiles -y
sudo apt install git -y
sudo su -
cd
git clone https://github.com/CISOfy/lynis.git
cd lynis/
./lynis audit system

sudo apt install aide -y
sudo aideinit
sudo mv /var/lib/aide/aide.db.nw /var/lib/aide/aide.db

sudo chkrootkit
sudo rkunter --check

sudo vipw | grep 'bin/bash/'
sudo vigr | grep 'sudo'

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


sudo reboot
