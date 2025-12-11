#!/usr/bin/env php
<?php
/**
 * OCI8 and PDO_OCI Installation Test Script
 *
 * This script verifies that OCI8 and PDO_OCI extensions are properly installed
 * and can be loaded by PHP.
 */

echo "========================================\n";
echo "PHP OCI8 Extension Test\n";
echo "========================================\n\n";

// Check PHP version
echo "PHP Version: " . PHP_VERSION . "\n";
echo "PHP API: " . PHP_SAPI . "\n\n";

// Test 1: Check if OCI8 extension is loaded
echo "Test 1: Checking OCI8 Extension...\n";
if (extension_loaded('oci8')) {
    echo "✓ OCI8 extension is loaded\n";

    // Get OCI8 version
    if (function_exists('oci_client_version')) {
        echo "  OCI8 Client Version: " . oci_client_version() . "\n";
    }

    // List OCI8 functions
    $oci8_functions = get_extension_funcs('oci8');
    echo "  Available OCI8 functions: " . count($oci8_functions) . "\n";
} else {
    echo "✗ OCI8 extension is NOT loaded\n";
    exit(1);
}

echo "\n";

// Test 2: Check if PDO_OCI extension is loaded
echo "Test 2: Checking PDO_OCI Extension...\n";
if (extension_loaded('pdo_oci')) {
    echo "✓ PDO_OCI extension is loaded\n";

    // Check if PDO driver is available
    $available_drivers = PDO::getAvailableDrivers();
    if (in_array('oci', $available_drivers)) {
        echo "✓ PDO OCI driver is available\n";
        echo "  Available PDO drivers: " . implode(', ', $available_drivers) . "\n";
    } else {
        echo "✗ PDO OCI driver is NOT available\n";
        exit(1);
    }
} else {
    echo "✗ PDO_OCI extension is NOT loaded\n";
    exit(1);
}

echo "\n";

// Test 3: Check Oracle Instant Client library path
echo "Test 3: Checking Oracle Instant Client...\n";
$ld_library_path = getenv('LD_LIBRARY_PATH');
if ($ld_library_path && strpos($ld_library_path, 'instantclient') !== false) {
    echo "✓ LD_LIBRARY_PATH contains instantclient\n";
    echo "  LD_LIBRARY_PATH: $ld_library_path\n";
} else {
    echo "⚠ LD_LIBRARY_PATH might not be set correctly\n";
    if ($ld_library_path) {
        echo "  LD_LIBRARY_PATH: $ld_library_path\n";
    }
}

// Try to find instantclient directory
$instant_dirs = glob('/opt/oracle/instantclient_*');
if (!empty($instant_dirs)) {
    echo "✓ Instant Client directory found: " . $instant_dirs[0] . "\n";

    // Check for key library files
    $lib_files = ['libclntsh.so', 'libocci.so', 'libclntshcore.so'];
    foreach ($lib_files as $lib) {
        $lib_path = $instant_dirs[0] . '/' . $lib;
        if (file_exists($lib_path)) {
            echo "  ✓ Found: $lib\n";
        }
    }
} else {
    echo "⚠ Instant Client directory not found in /opt/oracle/\n";
}

echo "\n";

// Test 4: Test OCI8 connection attempt (will fail without database, but tests function availability)
echo "Test 4: Testing OCI8 Functions...\n";
if (function_exists('oci_connect')) {
    echo "✓ oci_connect function is available\n";
} else {
    echo "✗ oci_connect function is NOT available\n";
    exit(1);
}

if (function_exists('oci_parse')) {
    echo "✓ oci_parse function is available\n";
} else {
    echo "✗ oci_parse function is NOT available\n";
    exit(1);
}

if (function_exists('oci_execute')) {
    echo "✓ oci_execute function is available\n";
} else {
    echo "✗ oci_execute function is NOT available\n";
    exit(1);
}

echo "\n";

// Test 5: Check all loaded extensions
echo "Test 5: All Loaded PHP Extensions:\n";
$extensions = get_loaded_extensions();
sort($extensions);
foreach ($extensions as $ext) {
    if (stripos($ext, 'oci') !== false || stripos($ext, 'pdo') !== false || stripos($ext, 'oracle') !== false) {
        echo "  • $ext (Oracle-related)\n";
    }
}

echo "\n========================================\n";
echo "✓ All tests passed successfully!\n";
echo "OCI8 and PDO_OCI are properly installed.\n";
echo "========================================\n";

exit(0);
