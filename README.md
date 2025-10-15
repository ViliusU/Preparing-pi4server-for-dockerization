# Preparing-pi4server-for-dockerization

1. When installing Raspberry Pi OS Lite version please remember user name and password of the main user of pi server because you will need to enter user name and password in github actions in the project >> settings >> actions >> PI_USERNAME , PI_PASSWORD, PI_HOST (your publicip with port, you might need to to port forwarding into your pi server).
2. sudo apt install git -y
3. git clone https://github.com/ViliusU/Preparing-pi4server-for-dockerization.git
4. cd Preparing-pi4server-for-dockerization
5. chmod +x prepare_pi4.sh
6. sudo ./prepare_pi4.sh
7. git clone https://<personal_access_token>@github.com/ViliusU/piserver-deployment
8. initiate commmit change and git push changes to piserver-deployment to trigger CI/CD pipeline
