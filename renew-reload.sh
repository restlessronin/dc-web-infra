#!/bin/sh

cd /srv/docker/certbot && \
    docker-compose -p webinfra -f docker-compose.yml run --rm certbot
docker exec nginx nginx -s reload
