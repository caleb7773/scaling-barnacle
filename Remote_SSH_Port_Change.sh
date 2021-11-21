#!/bin/bash

GR="\e[32m"
RE="\e[31m"
NC="\e[0m"

echo
read -p "New SSH Port you want: " ssh_port
read -p "Current SSH Port on remote server: " current_ssh
read -p "New RSA Key Name: " new_key
read -p "New SSH Config File Host Name: " host
read -p "Remote User: " user
read -p "Remote Server IP: " ip

echo
echo -e "${GR}Navigating to SSH Directory...${NC}"
cd ~/.ssh

echo -e "${GR}Creating SSH RSA Keys...${NC}"
ssh-keygen -t rsa -N "" -f ${new_key} > /dev/null

echo -e "${GR}Removing sensitive Information from public key...${NC}"
sudo sed -i 's/=.*./=/g' ${new_key}.pub > /dev/null

echo -e "${GR}Transferring public key over to remote server...${NC}"
ssh-copy-id -p ${current_ssh} -i ~/.ssh/${new_key} ${user}@${ip}

echo -e "${GR}Modifying the SSH config file to enable Host -> ${host}...${NC}"
echo "Host ${host}
     hostname ${ip}
     user ${user}
     port ${ssh_port}
     identityfile ~/.ssh/${new_key}
     " | sudo tee -a ~/.ssh/config > /dev/null

echo -e "${GR}Creating SSH Shell Script...${NC}"
echo "#!/bin/bash
ssh_port=${ssh_port}
sudo sed -i \"s/.*Port .*/Port ${ssh_port}/g\" /etc/ssh/sshd_config
sudo sed -i \"s/.*PubkeyAuthentication .*/PubkeyAuthentication yes/g\" /etc/ssh/sshd_config
sudo sed -i \"s/.*PermitRootLogin .*/PermitRootLogin no/g\" /etc/ssh/sshd_config
sudo sed -i \"s/.*PasswordAuthentication .*/PasswordAuthentication no/g\" /etc/ssh/sshd_config
sudo systemctl restart ssh
" | sudo tee /tmp/ssh.sh > /dev/null

sudo chmod +x /tmp/ssh.sh > /dev/null


echo -e "${GR}Modifing the SSH Port on remote host and restartin remote SSH Server...${NC}"
scp -P ${current_ssh} -i ~/.ssh/${new_key} /tmp/ssh.sh ${user}@${ip}:/tmp/ssh.sh
ssh -t -p ${current_ssh} -i ~/.ssh/${new_key} ${user}@${ip} 'sudo bash /tmp/ssh.sh'

echo
echo
echo
echo
echo -e "${GR}You can now SSH into ${ip} with your public key by running...${NC}"
echo -e " ${RE}ssh ${host}${NC}"
echo
echo -e " Additionally the following have been modified:"
echo -e " ${RE}SSH Port${NC} is now: ${GR}${ssh_port}${NC}"
echo -e " ${RE}PermitRootLogin${NC} has been set to ${GR}no${NC}"
echo -e " ${RE}PubKeyAuthentication${NC} has been set to ${GR}yes${NC}"
echo -e " ${RE}PasswordAuthentication${NC} has been set to ${GR}no${NC}"
echo
echo -e "${GR}Script complete!${NC}"
