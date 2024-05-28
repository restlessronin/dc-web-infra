# Setup for the 'llm_chat' app

The llm_chat app is served from www.cyberchitta.cc
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
docker compose exec postgres bash -c "/tmp/setup_db_and_roles.sh llm_chat chat 'rw-pwd' 'ro-pwd'"
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
git clone --depth 1 https://github.com/restlessronin/llm_chat.git /srv/dc-web-infra/llm_chat/repo

# build docker image
cd /srv/dc-web-infra/llm_chat/repo
docker build -t llm-chat -f ./dc-web-infra/Dockerfile .
cd ..

# delete repo
rm -r repo
```

## Add llm-chat-web service to `docker-compose.yml`

```yaml
  llm-chat-web:
    env_file: llm_chat/.env
    image: llm-chat
    networks:
      - infra_network
    depends_on:
      - postgres
```

## Add nginx https config with proxy to llm-chat-web service

Configure https to forward to llm-chat-web service

```nginx
server {
    listen 443 ssl;
    server_name www.cyberchitta.cc;

    ssl_certificate /etc/nginx/ssl/live/cyberchitta.cc/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/cyberchitta.cc/privkey.pem;

    location / {
        proxy_pass http://llm-chat-web:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Run migrations

```sh
docker run --env-file llm_chat/.env --rm --network webinfra_dc_net llm-chat bash -c "/app/run_migrations.sh"
```

## Start web service

```sh
docker compose up -d llm-chat-web
```
