#!/bin/bash
trap 'echo "Cleaning up!"; shred -u /tmp/users; exit' INT
sudo apt install whois -y
clear

if [ $(id -u) -eq 0 ]; then
      read -p "Enter username : " username
      read -s -p "Enter password : " password
      egrep "^$username" /etc/passwd >/dev/null
      if [ $? -eq 0 ]; then
            echo "$username exists!"
            exit 1
      else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -s /bin/bash -G sudo -p "$pass" "$username"
            [ $? -eq 0 ] && echo "User has been added to the system!" || echo "Failed to add a user!"
      fi
else
      echo "Only root may add a user to the system."
      exit 2
fi
read -p "Did it work?" test



intro_questions() {
      read -p "SSH Port: " ssh_port_num
      echo ' '
      read -p "New Username: " user_name
      echo ' '
      pass_hash=$(read -sp "New User Password: " | mkpasswd -m SHA-512 -s)
echo ' '
}
####################################################################
####################################################################

while [ "${ynvar:-n}" == "n" ]
do
        intro_questions
          clear
          echo "You are about to change the SSH port to ${ssh_port_num}"
          echo "You are about to build the following user as Root: ${user_name}"
          read -p "Are you sure? (Y/n) " ynvar
          #Grab y or n
          #changes input to lower case to match if line
          ynvar=$(echo $ynvar | tr '[A-Z]' '[a-z]')
          clear
done
sudo useradd -m -s /bin/bash -G sudo -U -p "${pass_hash}" "${user_name}"

####################################################################
####################################################################

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
echo 'export PS1="\[$(tput setaf 3; tput bold; tput rev)\]\u@\h:\w\$\[$(tput sgr0)\] "' >> ~/.bashrc
source ~/.bashrc
###############################
#Changes the SSH port to 20022#
###############################
sudo sed -i "s/#Port 22/Port ${ssh_port_num}/g" /etc/ssh/sshd_config
sudo systemctl restart ssh
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
#########################
#Installs Lynis from GIT#
#########################
sudo apt install git -y
sudo su -c "cd && git clone https://github.com/CISOfy/lynis.git && cd lynis/ && ./lynis audit system --quiet"
#################################
#Starts Aide and builds database#
#Run at the end after all change#
#################################
sudo apt install aide -y
sudo aideinit
sudo mv /var/lib/aide/aide.db.nw /var/lib/aide/aide.db




##########################
#Edit these for a baseline#
#sudo iptables -A INPUT -p icmp -j ACCEPT
#sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
#sudo iptables -A INPUT -i lo -j ACCEPT
#sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
#sudo iptables -A OUTPUT -m conntrack --ctstate INVALID -j DROP
#sudo iptables -A OUTPUT -o lo -j ACCEPT
#sudo iptables -A OUTPUT -p icmp -j ACCEPT
#sudo iptables -P OUTPUT DROP
#sudo iptables -P INPUT DROP
#####################################################




###################################
#Displays all users who can log in#
###################################
echo 'Users who can log onto your machine:' >> /tmp/users
echo ' ' >> /tmp/users
cat /etc/passwd | grep 'bin/bash' | cut -d ':' -f1 | tee -a /tmp/users
echo ' ' >> /tmp/users
echo ' ' >> /tmp/users
########################################
#Displays all users who are SUDO admins#
########################################
echo 'Users who can SUDO on your machine:' >> /tmp/users
echo ' ' >> /tmp/users
grep 'sudo' /etc/group | cut -d ':' -f4 | tee -a /tmp/users
clear
##################
#Restarts the box#
##################
cat /tmp/users
echo ' '
echo ' '
echo 'Now you know who has access to your box.'
echo ' '
read -p "Press Enter to reboot your machine....." enter
sudo shred -u /tmp/users

sudo reboot
