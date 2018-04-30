FROM php:7.1-apache
MAINTAINER Computer Science House

ENV LAM_VERSION=lam_6_3
ENV LAM_USER=lam
ENV LAM_DIR=/var/www/html

# Install dependencies and configure Apache
RUN BUILD_DEPENDENCIES="libmagickwand-dev libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libldb-dev libldap2-dev libcurl4-openssl-dev" \
    set -ex \
      && apt-get update \
      && apt-get install -y --force-yes --no-install-recommends ${BUILD_DEPENDENCIES} \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
      && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
      && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
      && docker-php-ext-install -j$(nproc) gettext ldap json curl zip \
      && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
      && docker-php-ext-install -j$(nproc) gd \
      && pecl install imagick-3.4.3 \
      && docker-php-ext-enable imagick \
      && sed -ie "s/\(\*:80\)/\180/g" /etc/apache2/sites-available/000-default.conf \
      && sed -i "s_DocumentRoot /var/www/html_DocumentRoot /var/www/html/lam_" /etc/apache2/sites-available/000-default.conf \
      && sed -ie "s/\(Listen 80\)/\180/g" /etc/apache2/ports.conf \
      && mkdir -p /var/lock/apache2 /var/run/apache2 \
      && chmod og+rwx /var/lock/apache2 /var/run/apache2

# Install LDAP Account Manager
RUN set -ex \
      && useradd -M -d ${LAM_DIR} ${LAM_USER} \
      && cd /tmp \
      && curl -o lam-${LAM_VERSION}.tar.gz -fsSL "https://github.com/LDAPAccountManager/lam/archive/${LAM_VERSION}.tar.gz" \
      && tar -xzf lam-${LAM_VERSION}.tar.gz \
      && cp -R lam-${LAM_VERSION}/* ${LAM_DIR} \
      && rm -rf /tmp/* \
      && cp ${LAM_DIR}/lam/config/config.cfg.sample ${LAM_DIR}/lam/config/config.cfg \
      && chown -R ${LAM_USER}:${LAM_USER} ${LAM_DIR} \
      && chmod og+rwx ${LAM_DIR}/lam/sess ${LAM_DIR}/lam/tmp \
      && chmod 777 ${LAM_DIR}/lam/config \
      && chmod 666 ${LAM_DIR}/lam/config/config.cfg

# Final steps
EXPOSE 8080
WORKDIR ${LAM_DIR}
USER ${LAM_USER}

