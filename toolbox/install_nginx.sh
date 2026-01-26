sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt install nginx -y

sudo systemctl enable nginx

mkdir /etc/nginx/ssl

sudo systemctl restart nginx
