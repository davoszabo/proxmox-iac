#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Packer connects as soon as sshd accepts the key, while cloud-init's package_update/upgrade
# may still hold the apt lock. Exit code 2 = finished with recoverable warnings, which is fine.
cloud-init status --wait >/dev/null || [ $? -eq 2 ]

IFS=, read -r -a packages <<< "${TEMPLATE_PACKAGES:-}"
IFS=, read -r -a services <<< "${TEMPLATE_SERVICES:-}"

apt-get update
if [ "${#packages[@]}" -gt 0 ]; then
  apt-get install -y --no-install-recommends "${packages[@]}"
fi

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

for service in "${services[@]}"; do
  systemctl enable "${service}"
done

# Drop build-only SSH access and reset cloud-init so clones get a fresh first boot.
rm -f "/home/${TEMPLATE_BUILD_USER:?}/.ssh/authorized_keys"
rm -f /root/.ssh/authorized_keys
rm -f /etc/ssh/ssh_host_*
cloud-init clean --logs --seed || true
rm -rf /var/lib/cloud /var/log/cloud-init.log /var/log/cloud-init-output.log
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

apt-get clean
rm -rf /var/lib/apt/lists/*
