#!/bin/bash
sed -i 's#docker#'"${myvar}"'#g' /var/www/default/public/index.php
composer install
php artisan migrate
php artisan db:seed

/usr/local/bin/entrypoint.sh