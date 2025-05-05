# Stage 1: Build stage (Install PHP dependencies)
FROM composer:latest AS builder
WORKDIR /dependencies
COPY composer.json ./

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Stage 2: Production stage (Nginx + PHP-FPM)
FROM php:8.1-fpm-alpine
RUN apk add --no-cache nginx curl libcurl && \
apk add --no-cache --virtual .build-deps \
    postgresql-dev \
    && apk add --no-cache libpq \
    && docker-php-ext-install pgsql \
    && apk del .build-deps

WORKDIR /app

# Copy the vendor directory from the builder stage to /dependencies
COPY --from=builder /dependencies/vendor /dependencies/vendor
COPY nginx.conf /etc/nginx/nginx.conf

# Update PHP include path to look for dependencies in /dependencies
RUN echo "include_path = \".:/dependencies/vendor\"" >> /usr/local/etc/php/php.ini
RUN chown -R www-data:www-data /app /dependencies

EXPOSE 8080
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]