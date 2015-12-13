FROM local-jessie:latest
MAINTAINER Joshua Cox <josh@webhosting.coop>
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  php5-mysql \
  php-apc \
  mysql-server \
  mysql-client \
  openssh-server \
  bzip2 \
  libapache2-mod-php5 \
  runit \
  git \
  lsb-release \
  acl \
  wget \
  unzip \
  php5-cli \
  php5-imap \
  php5-ldap \
  php5-curl \
  php5-intl \
  php5-gd \
  nodejs \
  sudo \
  vim \
  npm \
  php5-mcrypt \
  apache2 \
  nodejs-legacy \
  net-tools \
  ruby \
  rake

# Avoid key buffer size warnings and myisam-recover warnings
# See: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751840
RUN sed -i "s/^key_buffer\s/key_buffer_size\t/g" /etc/mysql/my.cnf
RUN sed -i "s/^myisam-recover\s/myisam-recover-options\t/g" /etc/mysql/my.cnf

# Avoid Apache complaint about server name
RUN echo "ServerName civicrm-buildkit" > /etc/apache2/conf-available/civicrm-buildkit.conf
RUN a2enconf civicrm-buildkit 

# Drupal requires mod rewrite.
RUN a2enmod rewrite

# We don't want to ever send email. But we also don't want an error when 
# Drupal or CiviCRM tries
RUN ln -s /bin/true /usr/sbin/sendmail

# Handle service starting with runit.
RUN mkdir /etc/sv/mysql /etc/sv/apache /etc/sv/sshd
COPY mysql.run /etc/sv/mysql/run
COPY apache.run /etc/sv/apache/run
COPY sshd.run /etc/sv/sshd/run
RUN update-service --add /etc/sv/mysql
RUN update-service --add /etc/sv/apache
RUN update-service --add /etc/sv/sshd

# Give ssh access via key
RUN mkdir /var/www/.ssh
COPY id_rsa.pub /var/www/.ssh/authorized_keys
COPY id_rsa.pub /root/.ssh/authorized_keys
RUN usermod -s /bin/bash www-data
RUN echo 'export PATH=/var/www/civicrm/civicrm-buildkit/bin:$PATH' > /var/www/.profile

RUN mkdir /var/www/civicrm

# Ensure www-data owns it's home directory so amp will work.
RUN chown -R www-data:www-data /var/www

# Allow www-data user to restart apache
RUN echo "www-data ALL=NOPASSWD: /usr/bin/sv restart apache, /usr/bin/sv reload apache, /usr/sbin/apache2ctl" > /etc/sudoers.d/civicrm-buildkit

## Allow www-data to run mysql cli tools
RUN echo "[client]" > /var/www/.my.cnf ; echo "user=root" >> /var/www/.my.cnf
RUN echo 'PATH=/var/www/civicrm/civicrm-buildkit/bin:$PATH'>>/var/www/.bashrc

COPY docker-entrypoint.sh /entrypoint.sh
COPY mkcivi.sh /usr/local/bin/mkcivi.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["runsvdir"]
