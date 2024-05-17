# dc-web-infra

Docker compose based infrastructure for web applications, including common services like nginx, postgres, and certbot. A blueprint for per-app compose files and environment settings can be used to add additional apps.

This project was created in collaboration with GPT-4o

## Prerequisites

- Docker
- Docker Compose

## Setup

1. **Clone the repository**:

   ```sh
   git clone --depth 1 <your-remote-repository-url> /srv/docker
   cd /srv/docker
   ```

2. **Copy the sample environment file and configure your settings**:

   ```sh
   cp .env.sample .env
   ```

   Edit `.env` to set your database user, password, and other configurations.

3. **Run the initialization script to create necessary directories**:

   ```sh
   ./init-dirs.sh
   ```

4. **Set the compose project name**
   ```sh
   export COMPOSE_PROJECT_NAME=webinfra
   ```

## Running the Services

1. **Start common services (Nginx and PostgreSQL)**:

   ```sh
   docker-compose up -d
   ```

2. **Start Certbot service for SSL certificates**:

   ```sh
   cd certbot
   docker-compose up -d
   cd ..
   ```

3. **Start app-specific services** (example for app1 and app2):

   ```sh
   docker-compose -f docker-compose.yml -f app1.docker-compose.yml --env-file .env --env-file app1.env up -d
   docker-compose -f docker-compose.yml -f app2.docker-compose.yml --env-file .env --env-file app2.env up -d
   ```

## Customizing Nginx Configuration

1. **Add your domain configuration**:

   - Edit or add configuration files in the `nginx/conf.d/` directory. You can use `example.org.conf` as a template.

2. **Example `example.org.conf` file**:

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
           return 301 https://example.org$request_uri;
       }
   }
   ```

3. **Customize the server_name and other settings**:

   - Replace `example.org` and `www.example.org` with your actual domain names.
   - Adjust other settings as needed for your specific requirements.

4. **Reload Nginx to apply the changes**:

   - After making changes to the Nginx configuration, ensure to reload Nginx to apply the new settings.

   ```sh
   docker exec nginx nginx -s reload
   ```

## Let's Encrypt SSL Certificates

## Renewing SSL Certificates

SSL certificates are renewed automatically via a cron job. To set up the cron job:

1. **Edit the cron jobs on the host**:

   ```sh
   crontab -e
   ```

2. **Add a cron job to run the renewal and reload script twice a day**:

   ```cron
   0 0,12 * * * /srv/docker/renew-reload.sh
   ```

This cron job will:

- Change to the certbot directory and run the Certbot container to renew certificates.
- Reload the Nginx configuration to apply the renewed certificates.

## Notes

- Ensure that all services are on the same Docker network (`infra_network`) for proper communication.
- The `renew-reload.sh` script runs the Certbot container for renewal and reloads the Nginx configuration.
