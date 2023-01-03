#!/bin/bash
sed -i 's#docker#'"${myvar}"'#g' /var/www/default/public/index.php
/usr/local/bin/entrypoint.sh