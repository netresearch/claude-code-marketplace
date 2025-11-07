## Error Handling

### Common Issues and Solutions

**1. Prerequisites Not Met**
```
❌ Prerequisites validation failed.

One or more requirements are not met:
  - Docker daemon not running
  - Docker CLI outdated (need >= 20.10)
  - Docker Compose outdated (need >= 2.0)
  - DDEV not installed

See "Prerequisites Validation" section above for detailed:
  - Platform-specific installation instructions
  - Version requirement details
  - Validation script you can run

Run the validation script to identify which prerequisite is failing.
```

**2. Docker Daemon Not Running (Most Common)**
```
❌ Docker daemon is not running.

Quick fix for your platform:

🐧 Linux/WSL2:
   sudo service docker start

🍎 macOS:
   Open Docker Desktop application

🪟 Windows:
   Open Docker Desktop application

For detailed instructions, see Prerequisites Validation section.
After starting Docker, run: docker info
```

**3. Not a TYPO3 Extension**
```
❌ This doesn't appear to be a TYPO3 extension project.

Requirements:
  - ext_emconf.php file present
  OR
  - composer.json with "type": "typo3-cms-extension"

Current directory: /path/to/project
```

**4. Port Conflicts**
```
❌ DDEV failed to start (port 80/443 conflict)

Solutions:
  - Stop other local web servers (Apache, Nginx, MAMP)
  - Or use different ports in .ddev/config.yaml:
    router_http_port: "8080"
    router_https_port: "8443"
```

**5. Installation Failures**
```
❌ TYPO3 installation failed

Troubleshooting:
  1. Check logs: ddev logs
  2. SSH into container: ddev ssh
  3. Check Composer: ddev composer diagnose
  4. Try reinstalling: rm -rf /var/www/html/v13/* && ddev install-v13
```

