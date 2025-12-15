sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt install nginx -y

sudo systemctl enable nginx

mkdir /etc/nginx/ssl

sudo openssl dhparam -out /etc/nginx/ssl/ssl-dhparams.pem 2048

sudo systemctl restart nginx

sudo apt install certbot -y
