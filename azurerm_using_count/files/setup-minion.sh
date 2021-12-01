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
  curl git jq sshpass
ret=$?
echo -ne "Installing packages... "
[ ${ret} -eq 0 ] && echo "[ OK ]" || echo "[ FAILED ]"

# Install salt-minion
curl -fsSL -o /usr/share/keyrings/salt-archive-keyring.gpg \
  https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3004/salt-archive-keyring.gpg
cat <<EOF > /etc/apt/sources.list.d/salt.list
deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3004 focal main
EOF
apt -y -q update
apt -y -q install salt-minion

# Configure salt-master
cat <<EOF > /etc/salt/minion.d/ssys.conf
master: master
ipv6: false
minion_id_lowercase: true
server_id_use_crc: adler32
enable_legacy_startup_events: false
enable_fqdns_grains: false
random_startup_delay: 10
log_level_logfile: error
acceptance_wait_time: 120
master_alive_interval: 300
random_reauth_delay: 120
recon_default: 5000
recon_max: 240000
recon_randomize: true
master_tops_first: true
grains_cache: true
pillarenv_from_saltenv: true
pillar_raise_on_missing: true
minion_pillar_cache: false
startup_states: 'highstate'
append_domain: ssys.lab
grains_deep_merge: true
grains_refresh_every: 30

schedule:
  schedule.present:
    function: state.highstate
    minutes: 120
    splay: 60
EOF

# Enable salt services
systemctl enable salt-minion
systemctl start salt-minion

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
