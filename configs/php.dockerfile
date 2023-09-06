FROM php:8.2-apache


# Install mysql stuff
RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql

# Install GD extension for image manipulation
RUN apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libzip-dev \
  zip \
  && docker-php-ext-configure gd \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-install zip


# Create a custom php.ini file
RUN echo "display_errors = Off" >> /usr/local/etc/php/php.ini \
  && echo "display_startup_errors = Off" >> /usr/local/etc/php/php.ini

# Replace the default Apache configuration with custom httpd.conf
COPY ./configs/apache/httpd.conf /etc/apache2/httpd.conf

# Enable Apache mod_rewrite for .htaccess support
RUN a2enmod rewrite

# Start Apache in the foreground
CMD ["apache2-foreground"]  

EXPOSE 443