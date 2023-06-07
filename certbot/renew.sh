echo "Trying to renew given domains..." >> /proc/1/fd/1
# Remove leading and trailing spaces then add before each domain the ' -d ' argument
parsed_domains="`echo "$DOMAINS" | tr -s [:space:]`"
parsed_domains="-d ${parsed_domains// / -d }"

#Free the port 80
/usr/sbin/nginx -s stop
sleep 5


certbot certonly --standalone --agree-tos -n -m $EMAIL $parsed_domains >> /proc/1/fd/1

$first_domain="`echo $parsed_domains | cut -d ' ' -f 2`"

$certs_folder="/etc/letsencrypt/live/$first_domain"

cp -f "$certs_folder/cert.pem" /srv/cert/cert.pem >> /proc/1/fd/1
cp -f "$certs_folder/chain.pem" /srv/cert/chain.pem >> /proc/1/fd/1
cp -f "$certs_folder/fullchain.pem" /srv/cert/fullchain.pem >> /proc/1/fd/1
cp -f "$certs_folder/privkey.pem" /srv/cert/privkey.pem >> /proc/1/fd/1


sleep 5
nginx -g 'daemon off;' &

echo "Finished renewing domains, check logs to confirm the success." >> /proc/1/fd/1
