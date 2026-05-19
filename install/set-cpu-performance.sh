#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "CPU 성능 모드 설정 시작"

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

echo ""
echo "🔄 systemd 설정을 적용하고 서비스를 활성화합니다..."
sudo systemctl daemon-reload
sudo systemctl enable cpu-performance.service
sudo systemctl start cpu-performance.service

echo ""
echo "✅ 설정 완료! 현재 CPU 상태:"
cpupower frequency-info | grep "The governor" || true

banner "CPU 성능 모드 설정 완료"
