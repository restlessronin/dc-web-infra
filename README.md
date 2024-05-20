# dc-web-infra

Docker compose based infrastructure for web applications, including common services like nginx, postgres, and certbot. A blueprint for per-app compose files and environment settings can be used to add additional apps.

This project was created in collaboration with GPT-4o

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Clone the repository:

   ```sh
   git clone --depth 1 <your-remote-repository-url> /srv/dc-web-infra
   cd /srv/dc-web-infra
   ```

2. Copy the sample environment files and configure:

   ```sh
   cp .env.template .env
   ```

   Edit `postgres.env` to set your superuser database user, password, and other configuration.

3. Run the initialization script to create necessary directories:

   ```sh
   ./init-dirs.sh
   ```

## Running the Services

1. Start common services (Nginx and probably PostgreSQL):

   ```sh
   docker-compose up -d nginx postgres
   ```

## Renewing Lets Encrypt SSL Certificates with certbot

SSL certificates are renewed automatically via a cron job. To set up the cron job:

1. Edit the cron jobs on the host:

   ```sh
   crontab -e
   ```

2. Add a cron job to run the renewal and reload script twice a day:

   ```cron
   0 0,12 * * * /srv/dc-web-infra/renew-reload.sh
   ```

This cron job will:

- Run the Certbot container to renew certificates.
- Reload the Nginx configuration to apply the renewed certificates.

## Notes

- Ensure that all services are on the same Docker network (`infra_network`) for proper communication.
