# Multi-version PHP with Oracle OCI8 support
# Build arguments for flexibility
ARG PHP_VERSION=8.4
ARG ORACLE_VERSION=21
ARG ORACLE_RELEASE=21.15.0.0.0

FROM php:${PHP_VERSION}-cli AS builder

# Set Oracle InstantClient version
ARG ORACLE_VERSION
ARG ORACLE_RELEASE

# Install dependencies
RUN apt-get update && apt-get install -yq \
    git \
    unzip \
    wget \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && (apt-get install -yq libaio1t64 || apt-get install -yq libaio1) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && if [ -f /usr/lib/x86_64-linux-gnu/libaio.so.1t64 ] && [ ! -f /usr/lib/x86_64-linux-gnu/libaio.so.1 ]; then \
        ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1; \
    fi

# Download and install Oracle Instant Client
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    if [ "$ORACLE_VERSION" = "19" ]; then \
        wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
        wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-sdk-linux.x64-19.23.0.0.0dbru.zip && \
        unzip -q instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
        unzip -q instantclient-sdk-linux.x64-19.23.0.0.0dbru.zip; \
    elif [ "$ORACLE_VERSION" = "21" ]; then \
        wget -q https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip && \
        wget -q https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip && \
        unzip -q instantclient-basic-linux.x64-21.13.0.0.0dbru.zip && \
        unzip -q instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip; \
    else \
        echo "Unsupported Oracle version: $ORACLE_VERSION" && exit 1; \
    fi && \
    # Create symlinks for compatibility
    INSTANT_DIR=$(ls -d instantclient_* | head -1) && \
    cd $INSTANT_DIR && \
    for lib in libclntsh.so libclntshcore.so libocci.so; do \
        versioned=$(ls ${lib}.* 2>/dev/null | head -1); \
        if [ -n "$versioned" ]; then \
            ln -sf $(basename $versioned) $lib; \
        fi; \
    done && \
    cd /opt/oracle && \
    rm -f *.zip

# Final stage
FROM php:${PHP_VERSION}-cli

ARG PHP_VERSION
ARG ORACLE_VERSION

LABEL maintainer="docker-php-oci8"
LABEL php.version="${PHP_VERSION}"
LABEL oracle.version="${ORACLE_VERSION}"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    git \
    unzip \
    && (apt-get install -y libaio1t64 || apt-get install -y libaio1) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig \
    && if [ -f /usr/lib/x86_64-linux-gnu/libaio.so.1t64 ] && [ ! -f /usr/lib/x86_64-linux-gnu/libaio.so.1 ]; then \
        ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1; \
    fi

# Copy Oracle Instant Client from builder
COPY --from=builder /opt/oracle /opt/oracle

# Set environment variables dynamically
RUN INSTANT_DIR=$(ls -d /opt/oracle/instantclient_* | head -1) && \
    mkdir -p /etc/profile.d && \
    echo "export LD_LIBRARY_PATH=$INSTANT_DIR:\${LD_LIBRARY_PATH}" >> /etc/profile.d/oracle.sh && \
    echo "export PATH=$INSTANT_DIR:\${PATH}" >> /etc/profile.d/oracle.sh && \
    echo "$INSTANT_DIR" > /opt/oracle/instant_dir.txt && \
    echo "$INSTANT_DIR" > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_21_13
ENV PATH=/opt/oracle/instantclient_21_13:${PATH}

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Determine OCI8 version based on PHP version
RUN PHP_MAJOR=$(php -r 'echo PHP_MAJOR_VERSION;') && \
    PHP_MINOR=$(php -r 'echo PHP_MINOR_VERSION;') && \
    INSTANT_DIR=$(ls -d /opt/oracle/instantclient_* | head -1) && \
    echo "Installing OCI8 for PHP $PHP_MAJOR.$PHP_MINOR" && \
    if [ "$PHP_MAJOR" -eq 7 ]; then \
        echo "PHP 7.x detected, installing oci8-2.2.0" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8-2.2.0; \
    elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 0 ]; then \
        echo "PHP 8.0 detected, installing oci8-3.0.1" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8-3.0.1; \
    elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 1 ]; then \
        echo "PHP 8.1 detected, installing oci8-3.2.1" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8-3.2.1; \
    elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 2 ]; then \
        echo "PHP 8.2 detected, installing oci8-3.3.0" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8-3.3.0; \
    elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 3 ]; then \
        echo "PHP 8.3 detected, installing oci8-3.4.0" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8-3.4.0; \
    else \
        echo "PHP 8.4+ detected, installing latest oci8" && \
        echo "instantclient,$INSTANT_DIR" | pecl install oci8; \
    fi && \
    docker-php-ext-enable oci8

# Install PDO_OCI
RUN INSTANT_DIR=$(ls -d /opt/oracle/instantclient_* | head -1) && \
    INSTANT_VERSION=$(basename $INSTANT_DIR | sed 's/instantclient_//' | tr '_' '.') && \
    PHP_MAJOR=$(php -n -r 'echo PHP_MAJOR_VERSION;') && \
    PHP_MINOR=$(php -n -r 'echo PHP_MINOR_VERSION;') && \
    echo "Configuring PDO_OCI for PHP $PHP_MAJOR.$PHP_MINOR" && \
    if [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 4 ]; then \
        echo "Installing PDO_OCI via PECL for PHP 8.4" && \
        echo "instantclient,$INSTANT_DIR" | pecl install pdo_oci && \
        docker-php-ext-enable pdo_oci; \
    else \
        echo "Installing PDO_OCI via docker-php-ext for PHP < 8.4" && \
        docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,$INSTANT_DIR,$INSTANT_VERSION && \
        docker-php-ext-install pdo_oci; \
    fi


# Add health check script
COPY test-oci8.php /usr/local/bin/test-oci8.php
RUN chmod +x /usr/local/bin/test-oci8.php

# Verify installation
RUN php -m | grep -i oci8 && php -m | grep -i pdo_oci

WORKDIR /app

CMD ["php", "-a"]
