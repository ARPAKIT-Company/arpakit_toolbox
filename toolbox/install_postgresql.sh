sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service