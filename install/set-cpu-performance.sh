#!/bin/bash
set -e

echo "CPU performance mode setup start"

sudo tee /etc/systemd/system/cpu-performance.service > /dev/null << 'SERVICE'
[Unit]
Description=Set CPU Governor to Performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

echo "Applying systemd configuration and enabling the service"
sudo systemctl daemon-reload
sudo systemctl enable cpu-performance.service
sudo systemctl start cpu-performance.service

echo "Setup complete. Current CPU governor:"
cpupower frequency-info | grep "The governor" || true

echo "CPU performance mode setup complete"
