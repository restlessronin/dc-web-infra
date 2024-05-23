# Setup for the 'mai' app

The mai app is served from www.cyberchitta.cc
The root of the dc-web-infra repo on the host is '/srv/sc-web-infra'

## Setting up Nginx configuration for domain cyberchitta.cc

1. Add your domain configuration:

   - Edit or add configuration files in the `nginx/conf.d/` directory.

2. Contents of `cyberchitta.cc.conf` file:

   ```nginx
   server {
       listen 80;
       listen [::]:80;

       server_name example.org www.example.org;
       server_tokens off;

       location /.well-known/acme-challenge/ {
           root /var/www/certbot;
       }

       location / {
           return 301 https://www.cyberchitta.cc$request_uri;
       }
   }
   ```

## Get Let's Encrypt SSL Certificate

1. ```sh
   docker compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d cyberchitta.cc
   ```

2. Reload Nginx to apply the changes:
   ```sh
   docker compose exec nginx nginx -s reload
   ```
## Initialize Database

```sh
docker cp /srv/dc-web-infra/setup_db_and_roles.sh webinfra-postgres-1:/tmp/setup_db_and_roles.sh
docker compose exec postgres bash -c "/tmp/setup_db_and_roles.sh mai chat 'rw-pwd' 'ro-pwd'"
```

## Copy db name and password to .env file (use .env.template as a template)

```env
POSTGRES_PASSWORD=rw-pwd
POSTGRES_DB=mai_chat
```

## Docker Image

### Build on server

```sh
# clone repo
git clone --depth 1 https://github.com/cyberchitta/M.ai.git /srv/dc-web-infra/mai/repo

# build docker image
cd /srv/dc-web-infra/mai/repo
docker build -t mai -f ./dc-web-infra/Dockerfile .
cd ..

# delete repo
rm -r repo
```

## Add mai-web service to `docker-compose.yml`

```yaml
  mai-web:
    env_file: mai/.env
    image: mai
    networks:
      - infra_network
    depends_on:
      - postgres
```

## Add nginx https config with proxy to mai-web service

Configure https to forward to mai-web service

```nginx
server {
    listen 443 ssl;
    server_name www.cyberchitta.cc;

    ssl_certificate /etc/nginx/ssl/live/cyberchitta.cc/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/cyberchitta.cc/privkey.pem;

    location / {
        proxy_pass http://mai-web:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Run migrations

```sh
docker run --env-file mai/.env --rm --network webinfra_dc_net mai bash -c "/app/run_migrations.sh"
```

## Start web service

```sh
docker compose up -d mai-web
```
