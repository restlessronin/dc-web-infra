FROM certbot/certbot:2.10.0
COPY run-certbot.sh /usr/local/bin/run-certbot.sh
RUN chmod +x /usr/local/bin/run-certbot.sh
ENTRYPOINT ["/usr/local/bin/run-certbot.sh"]
