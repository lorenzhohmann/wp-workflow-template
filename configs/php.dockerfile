FROM php:8.2-fpm-alpine


# Install mysql stuff
RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql

# update packages
RUN apk update

# Install imagick
RUN apk add --no-cache libpng-dev
RUN docker-php-ext-configure gd
RUN docker-php-ext-install -j "$(nproc)" gd

# Create a custom php.ini file
RUN echo "display_errors = Off" >> /usr/local/etc/php/php.ini \
  && echo "display_startup_errors = Off" >> /usr/local/etc/php/php.ini