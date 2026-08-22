#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  qemu-guest-agent \
  ufw \
  chrony \
  iotop \
  nfs-common \
  ca-certificates

if [ -d /tmp/certs ]; then
  find /tmp/certs -type f \( -name '*.crt' -o -name '*.pem' \) -exec cp {} /usr/local/share/ca-certificates/ \;
  if compgen -G "/usr/local/share/ca-certificates/*.crt" > /dev/null; then
    update-ca-certificates
  fi
  rm -rf /tmp/certs
fi

if [ -n "${TEMPLATE_TIMEZONE:-}" ] && [ -f "/usr/share/zoneinfo/${TEMPLATE_TIMEZONE}" ]; then
  ln -sf "/usr/share/zoneinfo/${TEMPLATE_TIMEZONE}" /etc/localtime
  echo "${TEMPLATE_TIMEZONE}" > /etc/timezone
fi

systemctl enable qemu-guest-agent
systemctl enable chrony

# Drop build-only SSH access and reset cloud-init so clones get a fresh first boot.
rm -f /home/debian/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys
rm -f /etc/ssh/ssh_host_*
cloud-init clean --logs --seed || true
rm -rf /var/lib/cloud /var/log/cloud-init.log /var/log/cloud-init-output.log
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

apt-get clean
rm -rf /var/lib/apt/lists/*
