#!/bin/bash

sudo yum update -y

cat << EOF > nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       443;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
	location / {
	  proxy_pass http://127.0.0.1:8090;
	}
    }
}
EOF

cat << EOF > docker-compose.yml
version: "2"
volumes:
    cmdbuild-db:
    cmdbuild-tomcat:

services:
    cmdbuild_db:
        image: itmicus/cmdbuild:db-3.0
        container_name: cmdbuild_db
        volumes:
            - cmdbuild-db:/var/lib/postgresql
        ports:
            - 5432:5432
        environment:
            - POSTGRES_USER=postgres
            - POSTGRES_PASS=postgres
        restart: always
        mem_limit: 1000m
        mem_reservation: 300m

    cmdbuild_app:
        image: itmicus/cmdbuild:app-3.1.1
        container_name: cmdbuild_app
        links:
           - cmdbuild_db
        depends_on:
           - cmdbuild_db
        ports:
            - 8090:8080
        restart: always
        volumes:
            - cmdbuild-tomcat:/usr/local/tomcat
        environment:
            - POSTGRES_USER=postgres
            - POSTGRES_PASS=postgres
            - POSTGRES_PORT=5432
            - POSTGRES_HOST=cmdbuild_db
            - POSTGRES_DB=cmdbuild_3
            - CMDBUILD_DUMP=demo
            - JAVA_OPTS=-Xmx4000m -Xms2000m
        mem_limit: 4000m
        mem_reservation: 2000m
EOF

mv nginx_cmdbuild.conf nginx.conf
sudo amazon-linux-extras install nginx1
sudo yum install -y nginx
sudo systemctl enable nginx
sudo cp nginx.conf /etc/nginx/
sudo systemctl start nginx

sudo yum install -y yum-utils
sudo yum update -y
sudo yum install -y docker
sudo wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /bin/docker-compose
sudo chmod -v +x /bin/docker-compose
sudo service docker start
cp docker-compose.yml /tmp/
cd /tmp/
sudo docker-compose up -d

sudo systemctl restart nginx
