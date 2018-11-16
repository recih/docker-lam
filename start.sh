#! /bin/bash -e

echo "restore configuration"
for f in $CONFIG; do
    rsync -a --ignore-existing $f.original/ $f/
    chown -R ${LAM_USER}:${LAM_USER} $f
    chmod -R a+rw $f
done

chmod 666 $CONFIG/config.cfg

! test -f /run/apache2/apache2.pid || rm /run/apache2/apache2.pid
apache2ctl -DFOREGROUND
