FROM php:7.2

RUN apt-get update && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget
#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
#codeception
RUN curl -LsS https://codeception.com/codecept.phar -o /usr/local/bin/codecept && chmod a+x /usr/local/bin/codecept


#ORACLE oci 

ADD instantclient-basiclite-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /tmp/

RUN unzip /tmp/instantclient-basiclite-linux.x64-12.2.0.1.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /usr/local/

RUN ln -s /usr/local/instantclient_12_2 /usr/local/instantclient
RUN ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

RUN echo 'export LD_LIBRARY_PATH="/usr/local/instantclient"' >> /root/.bashrc
RUN echo 'umask 002' >> /root/.bashrc

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8
RUN echo "extension=oci8.so" > /usr/local/etc/php/conf.d/php-oci8.ini


# ORACLE PDO_OCI

ARG php_version=7.2.12
RUN php -r 'exit(substr(PHP_VERSION, 0, strlen(getenv("php_version"))) === getenv("php_version") ? 0 : 1);'

RUN wget -O /tmp/php-${php_version}.zip \
        https://github.com/php/php-src/archive/php-${php_version}.zip
RUN unzip /tmp/php-${php_version}.zip -d /tmp

WORKDIR /tmp/php-src-php-${php_version}/ext/pdo_oci
RUN phpize
RUN ./configure --with-pdo-oci=instantclient,/usr/local/instantclient
RUN make install
WORKDIR /
RUN echo 'extension=pdo_oci.so' > /usr/local/etc/php/conf.d/pdo_oci.ini

CMD ext_dir=`php -r 'echo ini_get("extension_dir");'` && \
    host_owner=`stat -c '%u:%g' /host` && \
    cp "${ext_dir}/oci8.so" /host/oci8.so && \
    chown ${host_owner} /host/oci8.so && \
    cp "${ext_dir}/pdo_oci.so" /host/pdo_oci.so && \
    chown ${host_owner} /host/pdo_oci.so
