# Preparing-pi4server-for-dockerization

1. When installing Raspberry Pi OS Lite version please remember user name and password of the main user of pi server because you will need to enter user name and password in github actions in the project >> settings >> actions >> PI_USERNAME , PI_PASSWORD, PI_HOST (your publicip with port, you might need to to port forwarding into your pi server).
2. sudo apt install git -y
3. git config --global user.name "gitUserName"
4. git config --global user.email "emailaddres@mail.com"
5. git clone https://github.com/ViliusU/Preparing-pi4server-for-dockerization.git
6. cd Preparing-pi4server-for-dockerization
7. chmod +x prepare_pi4.sh
8. sudo ./prepare_pi4.sh
9. git clone https://<personal_access_token>@github.com/gitUserName/gitRepositoryName
10. initiate commmit change and git push changes to piserver-deployment to trigger CI/CD pipeline
