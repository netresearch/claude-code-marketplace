ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV EXTENSION_KEY "{{EXTENSION_KEY}}"
ENV DDEV_SITENAME "{{DDEV_SITENAME}}"

RUN echo "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>EXT:${EXTENSION_KEY} - DDEV Environment</title><style>" > /var/www/html/index.html
RUN echo "body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,Cantarell,sans-serif;max-width:900px;margin:50px auto;padding:0 20px;line-height:1.6;color:#333;background:#f5f5f5}" >> /var/www/html/index.html
RUN echo ".container{background:#fff;padding:40px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}" >> /var/www/html/index.html
RUN echo "h1{color:#ff8700;border-bottom:3px solid #ff8700;padding-bottom:10px;margin-bottom:30px}" >> /var/www/html/index.html
RUN echo "h2{color:#666;margin-top:30px;margin-bottom:15px;font-size:1.3em}" >> /var/www/html/index.html
RUN echo ".card{background:#f9f9f9;border-left:4px solid #ff8700;padding:20px;margin:15px 0;border-radius:4px}" >> /var/www/html/index.html
RUN echo ".card h3{margin-top:0;color:#ff8700}" >> /var/www/html/index.html
RUN echo "a{color:#0078e7;text-decoration:none;font-weight:500}" >> /var/www/html/index.html
RUN echo "a:hover{text-decoration:underline}" >> /var/www/html/index.html
RUN echo "code{background:#eee;padding:2px 6px;border-radius:3px;font-family:monospace;font-size:0.9em}" >> /var/www/html/index.html
RUN echo ".links{display:flex;gap:15px;margin-top:10px;flex-wrap:wrap}" >> /var/www/html/index.html
RUN echo ".btn{display:inline-block;padding:10px 20px;background:#0078e7;color:#fff!important;border-radius:4px;text-decoration:none;transition:background 0.3s}" >> /var/www/html/index.html
RUN echo ".btn:hover{background:#0056b3;text-decoration:none}" >> /var/www/html/index.html
RUN echo ".btn-docs{background:#ff8700}" >> /var/www/html/index.html
RUN echo ".btn-docs:hover{background:#e67700}" >> /var/www/html/index.html
RUN echo "ul{list-style:none;padding:0}" >> /var/www/html/index.html
RUN echo "li{padding:5px 0}" >> /var/www/html/index.html
RUN echo ".version-card{margin:10px 0}" >> /var/www/html/index.html
RUN echo "</style></head><body><div class=\"container\">" >> /var/www/html/index.html
RUN echo "<h1>🚀 EXT:${EXTENSION_KEY} Development Environment</h1>" >> /var/www/html/index.html
RUN echo "<div class=\"card\"><h3>📚 Documentation</h3><p>View the extension documentation (run <code>ddev docs</code> to render):</p><a href=\"https://docs.${DDEV_SITENAME}.ddev.site/\" class=\"btn btn-docs\">View Documentation</a></div>" >> /var/www/html/index.html
RUN echo "<div class=\"card\"><h3>🌐 TYPO3 Environments</h3>" >> /var/www/html/index.html
RUN echo "<div class=\"version-card\"><strong>TYPO3 11.5 LTS</strong><div class=\"links\"><a href=\"https://v11.${DDEV_SITENAME}.ddev.site/\" class=\"btn\">Frontend</a><a href=\"https://v11.${DDEV_SITENAME}.ddev.site/typo3/\" class=\"btn\">Backend</a></div></div>" >> /var/www/html/index.html
RUN echo "<div class=\"version-card\"><strong>TYPO3 12.4 LTS</strong><div class=\"links\"><a href=\"https://v12.${DDEV_SITENAME}.ddev.site/\" class=\"btn\">Frontend</a><a href=\"https://v12.${DDEV_SITENAME}.ddev.site/typo3/\" class=\"btn\">Backend</a></div></div>" >> /var/www/html/index.html
RUN echo "<div class=\"version-card\"><strong>TYPO3 13.4 LTS</strong><div class=\"links\"><a href=\"https://v13.${DDEV_SITENAME}.ddev.site/\" class=\"btn\">Frontend</a><a href=\"https://v13.${DDEV_SITENAME}.ddev.site/typo3/\" class=\"btn\">Backend</a></div></div>" >> /var/www/html/index.html
RUN echo "</div>" >> /var/www/html/index.html
RUN echo "<div class=\"card\"><h3>🔑 Backend Credentials</h3><ul><li><strong>Username:</strong> <code>admin</code></li><li><strong>Password:</strong> <code>Password:joh316</code></li><li><em>(also works for Install Tool)</em></li></ul></div>" >> /var/www/html/index.html
RUN echo "<div class=\"card\"><h3>⚙️ Quick Commands</h3><ul><li><code>ddev setup</code> - <strong>Complete setup (all-in-one)</strong></li><li><code>ddev docs</code> - Render documentation</li><li><code>ddev install-v11</code> - Install TYPO3 11.5 LTS</li><li><code>ddev install-v12</code> - Install TYPO3 12.4 LTS</li><li><code>ddev install-v13</code> - Install TYPO3 13.4 LTS</li><li><code>ddev install-all</code> - Install all TYPO3 versions</li></ul></div>" >> /var/www/html/index.html
RUN echo "</div></body></html>" >> /var/www/html/index.html


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
