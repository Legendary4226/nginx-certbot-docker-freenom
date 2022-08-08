echo "Reloading nginx to apply certificates changes." >> /proc/1/fd/1
nginx -s reload  >> /proc/1/fd/1