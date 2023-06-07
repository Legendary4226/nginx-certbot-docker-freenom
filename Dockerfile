FROM nginx:mainline-alpine


# For CERTBOT ------------
# Install Acme.sh, the script is placed at /usr/share/acme.sh/acme.sh
RUN apk add nano && \
    apk add certbot
RUN mkdir /srv/certs

COPY certbot/renew.sh /renew.sh
RUN chmod 777 /renew.sh

ENV EMAIL example@example.com
ENV DOMAINS web.example.com portainer.example.com another.domain.com
# ------------------------


# For NGINX ------------
# Add reload script and add a cron task each month
COPY nginx/reload-after-renew-certs.sh /reload-after-renew-certs.sh
RUN chmod 755 /reload-after-renew-certs.sh && \
    printf '0 5 1 * * /reload-after-renew-certs.sh >/dev/null 2>&1\n' >> /etc/crontabs/root

COPY nginx/default.conf /default.conf
RUN chmod 755 /etc/nginx/conf.d/default.conf

ENV NGINX_CONF_D /home/docker/nginx/conf.d
ENV CERT_FOLDER /srv/cert
ENV GENERATE_DEFAULT_CONF true
# ------------------------


# Official modified Nginx script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh


VOLUME [ "/srv/cert" ]
VOLUME [ "/etc/nginx/conf.d" ]


ENTRYPOINT [ "/docker-entrypoint.sh" ]
