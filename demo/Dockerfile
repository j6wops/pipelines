FROM j6wdev/rel:php8
WORKDIR /var/www/default/public
COPY . .
RUN chmod +x runner.sh 
CMD [ "/var/www/default/public/runner.sh" ]