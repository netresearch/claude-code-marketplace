#!/bin/bash
# Remove stale Debian default index.html if it exists
# This ensures index.php is served instead
# The index.html can persist in Docker volumes across rebuilds
if [ -f /var/www/html/index.html ]; then
    # Check if it's the Debian default page
    if grep -q "Apache2 Debian Default Page" /var/www/html/index.html 2>/dev/null; then
        rm -f /var/www/html/index.html
        echo "Removed stale Debian default index.html"
    fi
fi
