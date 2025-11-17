ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV EXTENSION_KEY "{{EXTENSION_KEY}}"
ENV DDEV_SITENAME "{{DDEV_SITENAME}}"
ENV GITHUB_URL "{{GITHUB_URL}}"

# Remove default Apache index.html and create PHP-based landing page
RUN rm -f /var/www/html/index.html
RUN cat > /var/www/html/index.php << 'PHPEOF'
<?php
// Get git info from runtime file (updated automatically on each ddev start)
$gitInfoFile = '/var/www/html/.git-info.json';
$gitInfo = file_exists($gitInfoFile) ? json_decode(file_get_contents($gitInfoFile), true) : [];

$gitBranch = $gitInfo['branch'] ?? 'unknown';
$gitCommit = $gitInfo['commit'] ?? 'unknown';
$prNumber = isset($gitInfo['pr']) && $gitInfo['pr'] !== 'unknown' ? $gitInfo['pr'] : null;

$githubUrl = '{{GITHUB_URL}}';
$branchUrl = $githubUrl && $gitBranch !== 'unknown' ? $githubUrl . '/tree/' . urlencode($gitBranch) : null;
$prUrl = $githubUrl && $prNumber ? $githubUrl . '/pull/' . $prNumber : null;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXT:{{EXTENSION_KEY}} - DDEV Environment</title>
    <style>
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,Cantarell,sans-serif;max-width:900px;margin:50px auto;padding:0 20px;line-height:1.6;color:#333;background:#f5f5f5}
        .container{background:#fff;padding:40px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}
        h1{color:#ff8700;border-bottom:3px solid #ff8700;padding-bottom:10px;margin-bottom:10px}
        .git-info{font-size:0.85em;color:#666;margin-bottom:30px;padding:10px;background:#f9f9f9;border-radius:4px}
        .git-info a{color:#0078e7;text-decoration:none;font-weight:500}
        .git-info a:hover{text-decoration:underline}
        .git-info .separator{margin:0 8px;color:#ccc}
        h2{color:#666;margin-top:30px;margin-bottom:15px;font-size:1.3em}
        .card{background:#f9f9f9;border-left:4px solid #ff8700;padding:20px;margin:15px 0;border-radius:4px}
        .card h3{margin-top:0;color:#ff8700}
        a{color:#0078e7;text-decoration:none;font-weight:500}
        a:hover{text-decoration:underline}
        code{background:#eee;padding:2px 6px;border-radius:3px;font-family:monospace;font-size:0.9em}
        .links{display:flex;gap:15px;margin-top:10px;flex-wrap:wrap}
        .btn{display:inline-block;padding:10px 20px;background:#0078e7;color:#fff!important;border-radius:4px;text-decoration:none;transition:background 0.3s}
        .btn:hover{background:#0056b3;text-decoration:none}
        .btn-docs{background:#ff8700}
        .btn-docs:hover{background:#e67700}
        ul{list-style:none;padding:0}
        li{padding:5px 0}
        .version-card{margin:10px 0}
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 EXT:{{EXTENSION_KEY}} Development Environment</h1>
        <?php if ($gitBranch !== 'unknown' || $prNumber): ?>
        <div class="git-info">
            <?php if ($branchUrl): ?>
                <a href="<?= htmlspecialchars($branchUrl) ?>" target="_blank" title="View branch on GitHub">
                    🌿 <?= htmlspecialchars($gitBranch) ?><?php if ($gitCommit !== 'unknown'): ?> @ <?= htmlspecialchars($gitCommit) ?><?php endif; ?>
                </a>
            <?php elseif ($gitBranch !== 'unknown'): ?>
                🌿 <?= htmlspecialchars($gitBranch) ?><?php if ($gitCommit !== 'unknown'): ?> @ <?= htmlspecialchars($gitCommit) ?><?php endif; ?>
            <?php endif; ?>
            <?php if ($prUrl): ?>
                <span class="separator">|</span>
                <a href="<?= htmlspecialchars($prUrl) ?>" target="_blank" title="View pull request">
                    🔀 PR #<?= htmlspecialchars($prNumber) ?>
                </a>
            <?php endif; ?>
        </div>
        <?php endif; ?>
        <div class="card">
            <h3>📚 Documentation</h3>
            <p>View the extension documentation (run <code>ddev docs</code> to render):</p>
            <a href="https://docs.{{DDEV_SITENAME}}.ddev.site/" class="btn btn-docs">View Documentation</a>
        </div>
        <div class="card">
            <h3>🌐 TYPO3 Environments</h3>
            <div class="version-card">
                <strong>TYPO3 11.5 LTS</strong>
                <div class="links">
                    <a href="https://v11.{{DDEV_SITENAME}}.ddev.site/" class="btn">Frontend</a>
                    <a href="https://v11.{{DDEV_SITENAME}}.ddev.site/typo3/" class="btn">Backend</a>
                </div>
            </div>
            <div class="version-card">
                <strong>TYPO3 12.4 LTS</strong>
                <div class="links">
                    <a href="https://v12.{{DDEV_SITENAME}}.ddev.site/" class="btn">Frontend</a>
                    <a href="https://v12.{{DDEV_SITENAME}}.ddev.site/typo3/" class="btn">Backend</a>
                </div>
            </div>
            <div class="version-card">
                <strong>TYPO3 13.4 LTS</strong>
                <div class="links">
                    <a href="https://v13.{{DDEV_SITENAME}}.ddev.site/" class="btn">Frontend</a>
                    <a href="https://v13.{{DDEV_SITENAME}}.ddev.site/typo3/" class="btn">Backend</a>
                </div>
            </div>
        </div>
        <div class="card">
            <h3>🔑 Backend Credentials</h3>
            <ul>
                <li><strong>Username:</strong> <code>admin</code></li>
                <li><strong>Password:</strong> <code>Password:joh316</code></li>
                <li><em>(also works for Install Tool)</em></li>
            </ul>
        </div>
        <div class="card">
            <h3>⚙️ Quick Commands</h3>
            <ul>
                <li><code>ddev setup</code> - <strong>Complete setup (all-in-one)</strong></li>
                <li><code>ddev docs</code> - Render documentation</li>
                <li><code>ddev install-v11</code> - Install TYPO3 11.5 LTS</li>
                <li><code>ddev install-v12</code> - Install TYPO3 12.4 LTS</li>
                <li><code>ddev install-v13</code> - Install TYPO3 13.4 LTS</li>
                <li><code>ddev install-all</code> - Install all TYPO3 versions</li>
            </ul>
        </div>
    </div>
</body>
</html>
PHPEOF

RUN mkdir -p /var/www/html/v11/public/typo3
RUN echo "<h1>Perform this first</h1> <code>ddev install-v11</code>" > /var/www/html/v11/public/index.html
RUN echo "<h1>Perform this first</h1> <code>ddev install-v11</code>" > /var/www/html/v11/public/typo3/index.html

RUN mkdir -p /var/www/html/v12/public/typo3
RUN echo "<h1>Perform this first</h1> <code>ddev install-v12</code>" > /var/www/html/v12/public/index.html
RUN echo "<h1>Perform this first</h1> <code>ddev install-v12</code>" > /var/www/html/v12/public/typo3/index.html

RUN mkdir -p /var/www/html/v13/public/typo3
RUN echo "<h1>Perform this first</h1> <code>ddev install-v13</code>" > /var/www/html/v13/public/index.html
RUN echo "<h1>Perform this first</h1> <code>ddev install-v13</code>" > /var/www/html/v13/public/typo3/index.html

ARG uid
ARG gid
RUN chown -R $uid:$gid /var/www/html
