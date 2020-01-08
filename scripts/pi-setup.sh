#!/bin/bash
set -e

ip_address="$1"
test -n "$ip_address" || { >&2 echo "The first argument must be an IP address"; exit 2; }

echo "Upgrading..."
sudo apt-get update && \
  sudo apt-get upgrade -y

boot_file=/boot/firmware/nobtcmd.txt
if ! grep "cgroup_memory=1" "$boot_file"; then
  echo
  echo "Enabling memory cgroups..."
  echo -n "$(cat "$boot_file") cgroup_enable=memory cgroup_memory=1" | sudo tee "$boot_file"
  echo
fi

netplan_file=/etc/netplan/50-cloud-init.yaml
if ! grep "$ip_address" "$netplan_file" &>/dev/null; then
  echo
  echo "Setting static IP address ${ip_address}..."
  cat <<EOT | sudo tee "$netplan_file"
network:
  ethernets:
      eth0:
          dhcp4: false
          dhcp6: false
          addresses: [${ip_address}/24]
          gateway4: 10.0.1.1
          nameservers:
              addresses: [8.8.8.8,8.8.4.4]
  version: 2
EOT
fi

echo
echo "Deleting setup script..."
rm -f ~/pi-setup.sh

echo
echo "Rebooting ..."
sudo reboot

# sudo systemctl enable ssh && sudo systemctl start ssh
# ifconfig

# ssh pi@10.0.1.2
# (umask 077 && mkdir -p .ssh) && (umask 066 && vi .ssh/authorized_keys)