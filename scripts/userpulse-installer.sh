#!/bin/bash
set -e

# Install Prometheus
sudo apt-get update -y
sudo apt-get install -y prometheus

# Create dummy log generator app
cat <<EOL | sudo tee /usr/local/bin/userpulse-loggen.sh
while true; do
  echo "[\$(date)] UserPulse event: user clicked dashboard" >> /mnt/logs/userpulse.log
  sleep 5
done
EOL

# Make it executable
sudo chmod +x /usr/local/bin/userpulse-loggen.sh

# Create systemd service for log generator
cat <<EOF | sudo tee /etc/systemd/system/userpulse.service
[Unit]
Description=UserPulse log generator
After=network.target

[Service]
ExecStart=/usr/local/bin/userpulse-loggen.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable userpulse
sudo systemctl start userpulse
