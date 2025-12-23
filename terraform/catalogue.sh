#!/bin/bash
set -e
sudo setenforce 0
app_version=$1
echo "APP_VERSION = $app_version"

# Base packages
yum install -y epel-release
yum install -y vim unzip git ansible

# Create explicit inventory forcing platform-python
cat <<EOF >/tmp/inventory
localhost ansible_connection=local ansible_python_interpreter=/usr/libexec/platform-python
EOF

cd /tmp
ansible-pull \
  -i /tmp/inventory \
  -U https://github.com/Sarthakx67/RoboShop-Ansible-Roles-tf.git \
  -e component=catalogue \
  -e APP_VERSION=${app_version} \
  main.yaml
