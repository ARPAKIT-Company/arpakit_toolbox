sudo apt-get update -y
sudo apt-get upgrade -y

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt install -y postgresql-16 postgresql-contrib-16


sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service

sudo apt install postgresql-client-16