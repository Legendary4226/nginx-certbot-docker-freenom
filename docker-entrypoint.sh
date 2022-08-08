#!/bin/sh
# vim:sw=4:ts=4:et

# This is the default entrypoint file of nginx official repo. My adds at are the end !

set -e

if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&1
else
    exec 3>/dev/null
fi

if [ "$1" = "nginx" -o "$1" = "nginx-debug" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        echo >&3 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        echo >&3 "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.sh)
                    if [ -x "$f" ]; then
                        echo >&3 "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        echo >&3 "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) echo >&3 "$0: Ignoring $f";;
            esac
        done

        echo >&3 "$0: Configuration complete; ready for start up"
    else
        echo >&3 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi



# Start cron service
crond

# NGINX If the GENERATE_DEFAULT_CONF ENV is set to true AND the /etc/nginx/conf.d folder is empty.
if  [[ "$GENERATE_DEFAULT_CONF" == "true" ]] &&
    [[ -z "$(ls -A /etc/nginx/conf.d)" ]]; then
    echo "Generating the default.conf file." >> /proc/1/fd/1
    cp /default.conf /etc/nginx/conf.d/default.conf >> /proc/1/fd/1
fi

# CERTBOT
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


nginx -g 'daemon off;'

while true; do
    sleep 1h
done