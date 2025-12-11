# docker-php-oci8

[![Docker Build and Test](https://github.com/vitoo/docker-php-oci8/actions/workflows/test.yml/badge.svg)](https://github.com/vitoo/docker-php-oci8/actions/workflows/test.yml)

Docker images with PHP, OCI8, PDO_OCI, and Oracle Instant Client - supporting multiple PHP and Oracle versions.

## Features

- ✅ **Multiple PHP versions**: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4
- ✅ **Oracle Instant Client**: 21c (compatible with Oracle DB 11g-23c)
- ✅ **OCI8 and PDO_OCI**: Both extensions included and working

## Supported Combinations

| PHP Version | Oracle Instant Client | Image Tag |
|-------------|----------------------|-----------|
| 8.4 | 21c | `php-oci8:8.4`  |
| 8.3 | 21c | `php-oci8:8.3`  |
| 8.2 | 21c | `php-oci8:8.2`  |
| 8.1 | 21c | `php-oci8:8.1`  |
| 8.0 | 21c | `php-oci8:8.0`  |
| 7.4 | 21c | `php-oci8:7.4`  |

**Note:** All versions use Oracle 21c Instant Client, which is compatible with Oracle Database 11g, 12c, 18c, 19c, 21c, and 23c.

## Quick Start

### Option 1: Pull from Docker Hub (Recommended)

```bash
# Latest version (PHP 8.4 + Oracle 21c)
docker pull donvito/php-oci8:latest

# Specific version
docker pull donvito/php-oci8:8.4
docker pull donvito/php-oci8:8.3
docker pull donvito/php-oci8:8.2
```

### Option 2: Build Locally

```bash
# Build with default versions (PHP 8.4 + Oracle 21c)
docker build -t php-oci8 .

# Build with specific versions
docker build --build-arg PHP_VERSION=8.3 --build-arg ORACLE_VERSION=21 -t php-oci8:8.3 .
docker build --build-arg PHP_VERSION=8.2 --build-arg ORACLE_VERSION=21 -t php-oci8:8.2 .
```

## Usage

### Interactive PHP shell

```bash
docker run -it --rm donvito/php-oci8:8.4 php -a
```

### List installed PHP modules

```bash
docker run --rm donvito/php-oci8:8.4 php -m
```

You'll see `oci8` and `pdo_oci` in the output.

### Run a PHP script

```bash
docker run --rm -v $(pwd):/app donvito/php-oci8:8.4 php /app/your-script.php
```

### Run the test suite

```bash
docker run --rm donvito/php-oci8:8.4 php /usr/local/bin/test-oci8.php
```

### Using in your own Dockerfile

```dockerfile
FROM donvito/php-oci8:8.4

COPY . /app
WORKDIR /app

RUN composer install

CMD ["php", "index.php"]
```


## Connecting to Oracle Database

### Using OCI8

```php
<?php
$conn = oci_connect('username', 'password', 'localhost:1521/XEPDB1');
if (!$conn) {
    $e = oci_error();
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

$stid = oci_parse($conn, 'SELECT * FROM your_table');
oci_execute($stid);

while ($row = oci_fetch_array($stid, OCI_ASSOC+OCI_RETURN_NULLS)) {
    print_r($row);
}

oci_free_statement($stid);
oci_close($conn);
?>
```

### Using PDO_OCI

```php
<?php
try {
    $pdo = new PDO('oci:dbname=localhost:1521/XEPDB1', 'username', 'password');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->query('SELECT * FROM your_table');
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
} catch (PDOException $e) {
    echo 'Connection failed: ' . $e->getMessage();
}
?>
```

## Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `PHP_VERSION` | `8.4` | PHP version to use (7.4, 8.0, 8.1, 8.2, 8.3, 8.4) |
| `ORACLE_VERSION` | `21` | Oracle Instant Client version (19, 21) |
| `ORACLE_RELEASE` | `21.15.0.0.0` | Specific Oracle release (auto-set based on ORACLE_VERSION) |


## Links

- [PHP OCI8 Documentation](https://www.php.net/manual/en/book.oci8.php)
- [Oracle Instant Client Downloads](https://www.oracle.com/database/technologies/instant-client/downloads.html)


