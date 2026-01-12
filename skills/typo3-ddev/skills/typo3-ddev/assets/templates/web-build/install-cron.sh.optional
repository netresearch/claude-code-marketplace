#!/bin/bash

# Install cron in web container (alternative to Ofelia)
# This script sets up traditional cron jobs in the web container

cat > /etc/cron.d/typo3-scheduler << 'EOF'
# TYPO3 Scheduler - runs every minute for all versions
* * * * * www-data cd /var/www/html/v11 && [ -f vendor/bin/typo3 ] && vendor/bin/typo3 scheduler:run > /dev/null 2>&1
* * * * * www-data cd /var/www/html/v12 && [ -f vendor/bin/typo3 ] && vendor/bin/typo3 scheduler:run > /dev/null 2>&1
* * * * * www-data cd /var/www/html/v13 && [ -f vendor/bin/typo3 ] && vendor/bin/typo3 scheduler:run > /dev/null 2>&1

# Optional: Cache warmup every hour
0 * * * * www-data cd /var/www/html/v13 && vendor/bin/typo3 cache:warmup > /dev/null 2>&1
EOF

chmod 0644 /etc/cron.d/typo3-scheduler
crontab /etc/cron.d/typo3-scheduler

# Start cron daemon
service cron start
