#!/bin/bash
read -p "Who is the current user? " user_var
git clone https://github.com/caleb7773/scaling-barnacle.git
sudo chmod +x ./scaling-barnacle/startup2.sh
/home/${user_var}/scaling-barnacle/startup2.sh



