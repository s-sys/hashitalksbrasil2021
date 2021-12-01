#!/bin/bash

# Redirect bash output
LOG_FILE="/root/cloud-init-setup.log"
exec > $LOG_FILE 2>&1

# Exit case control file exists
[ -f /root/setup.done ] && exit 0

# Load terraform vars
while [ ! -f /run/scripts/vars ]; do sleep 1; done
source /run/scripts/vars

# Update packages
apt -y -q update

# Disable network capabilities in network
echo -ne "Configuring network... "
cat <<EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF

# Setup swap using Azure device block
echo -ne "Configuring Azure Linux Agent... "
{
sed -i "s/ResourceDisk.Format=n/ResourceDisk.Format=y/" /etc/waagent.conf
sed -i "s/ResourceDisk.MountPoint=.*/ResourceDisk.MountPoint=\/mnt\/swapfile/" /etc/waagent.conf
sed -i "s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/" /etc/waagent.conf
sed -i "s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=${vm_swap_size}/" /etc/waagent.conf
sed -i "s/AutoUpdate.Enabled=n/AutoUpdate.Enabled=y/" /etc/waagent.conf
systemctl restart walinuxagent.service
}
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Disable Ubuntu frontend
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Update system
apt -y -q upgrade
DEBIAN_FRONTEND=noninteractive apt -y -q install bash-completion \
  vim net-tools uuid rsyslog apparmor-utils mlocate iputils-ping \
  sysstat iotop apt-transport-https ca-certificates software-properties-common \
  curl git jq sshpass
ret=$?
echo -ne "Installing packages... "
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Purge uneeded packages
apt -y -q purge snapd

# Enable services
echo -ne "Adjusting services... "
{
systemctl enable rsyslog.service
systemctl disable apparmor.service
systemctl disable atd.service
}
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Update locate database
echo -ne "Updating mlocate... "
updatedb
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Create control file to complete setup
echo -ne "Finishing update and creating control file... "
touch /root/setup.done
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Rebooting
echo "Rebooting... "
reboot
