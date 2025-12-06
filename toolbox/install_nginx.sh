sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt install nginx

sudo systemctl enable nginx

mkdir /etc/nginx/ssl

sudo openssl dhparam -out /etc/nginx/ssl-dhparams.pem 4096

sudo systemctl restart nginx
