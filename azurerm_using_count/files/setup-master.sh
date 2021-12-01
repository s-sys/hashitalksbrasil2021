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
# ResourceDisk.Format=y
# ResourceDisk.Filesystem=ext4
# ResourceDisk.MountPoint=/mnt/resource
# ResourceDisk.MountOptions=None
# ResourceDisk.EnableSwap=y
# ResourceDisk.SwapSizeMB=${vm_swap_size}
echo -ne "Configuring Azure Linux Agent... "
sed -i "s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/" /etc/waagent.conf
sed -i "s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=${vm_swap_size}/" /etc/waagent.conf
systemctl restart walinuxagent.service
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Disable Ubuntu frontend
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Update system
apt -y -q upgrade
DEBIAN_FRONTEND=noninteractive apt -y -q install bash-completion \
  vim net-tools uuid rsyslog apparmor-utils mlocate iputils-ping \
  sysstat iotop apt-transport-https ca-certificates software-properties-common \
  curl git jq sshpass python3 python3-pip python3-dev libpq-dev build-essential
ret=$?
echo -ne "Installing packages... "
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Install salt-master
curl -fsSL -o /usr/share/keyrings/salt-archive-keyring.gpg \
  https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3004/salt-archive-keyring.gpg
cat <<EOF > /etc/apt/sources.list.d/salt.list
deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3004 focal main
EOF
apt -y -q update
apt -y -q install salt-master salt-api

# Clone the integration repository
git clone https://ssys:yaJ5WMddDsFH-fmfAkqm@gitlab.ssys.com.br/lucas.sanches/saltconf21.git /root/saltconf21

# Install docker and docker-compose
sh -c "$(curl -sSL https://get.docker.com)"
curl -sSL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Update pip and install requirements
pip3 install -U pip wheel setuptools
pip3 install -r /root/saltconf21/salt_master/requirements.txt

# Configure salt-master
mkdir -p /srv/salt/
cp /root/saltconf21/salt_master/etc/salt/master.d/* /etc/salt/master.d/
cp /root/saltconf21/salt_master/srv/salt/* /srv/salt/

# Make sure the salt-master can connect to postgres
echo "127.0.0.1  postgres" >> /etc/hosts

# Enable salt services
systemctl enable salt-master
systemctl enable salt-api
systemctl start salt-master
systemctl start salt-api

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

# Start the integration containers
docker-compose -f /root/saltconf21/docker-compose.yml -f /root/saltconf21/docker-compose.prod.yml build
docker-compose -f /root/saltconf21/docker-compose.yml -f /root/saltconf21/docker-compose.prod.yml up -d

# Create control file to complete setup
echo -ne "Finishing update and creating control file... "
touch /root/setup.done
ret=$?
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Rebooting
echo "Rebooting... "
reboot
