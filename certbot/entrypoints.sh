#!/bin/sh


if  [[ "$DOMAINS" != "web.example.com portainer.example.com another.domain.com" ]] &&
    [[ "$EMAIL" != "example@example.com" ]]; then

    echo "Trying to certify given domains..." >> /proc/1/fd/1
    # Remove leading and trailing spaces then add before each domain the ' -d ' argument
    parsed_domains=`echo "$DOMAINS" | tr -s [:space:]`
    parsed_domains="-d ${parsed_domains// / -d }"


    certbot certonly --standalone --agree-tos -n -m $EMAIL $parsed_domains >> /proc/1/fd/1

    $first_domain=`echo $parsed_domains | cut -d ' ' -f 2`

    $certs_folder="/etc/letsencrypt/live/$first_domain"

    mv -f "$certs_folder/cert.pem" /srv/cert/cert.pem >> /proc/1/fd/1
    mv -f "$certs_folder/chain.pem" /srv/cert/chain.pem >> /proc/1/fd/1
    mv -f "$certs_folder/fullchain.pem" /srv/cert/fullchain.pem >> /proc/1/fd/1
    mv -f "$certs_folder/privkey.pem" /srv/cert/privkey.pem >> /proc/1/fd/1

    echo "Finished certifying domains, check logs to confirm the creation." >> /proc/1/fd/1
    echo "" >> /proc/1/fd/1
    echo "Creating CRON task for automatic renew..." >> /proc/1/fd/1
    printf '0 4 1 * * /renew.sh >/dev/null 2>&1\n' >> /etc/crontabs/root
    echo "Created CRON task." >> /proc/1/fd/1

    crond
else
    echo "Default ENV values detected, can't certify domains." >> /proc/1/fd/1
fi


while true; do
    sleep 1h
done