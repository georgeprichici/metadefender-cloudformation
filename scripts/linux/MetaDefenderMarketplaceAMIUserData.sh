#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Update the VM"
sudo yum update -y

INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

echo "Create opswat temp folder for config file..."
sudo mkdir /etc/opswat
cd /etc/opswat
INI_FILE='/etc/opswat/ometascan.ini'
echo "Create init file..."
sudo touch ${INI_FILE}

cat << EOF > ${INI_FILE}
eula=true
[user]
name=admin
password=${INSTANCE_ID}
email=admin@local
EOF

echo "Update permissions for the ini file and folder..."
sudo chmod 777 ${INI_FILE}
sudo chmod 755 .

echo "Download MetaDefender installer"
INSTALLER_URL='https://metascanbucket.s3.amazonaws.com/Metadefender/Core/v4/4.17.3-1/centos/ometascan-4.17.3-1.x86_64.rpm'
INSTALLER_FILE=$(basename "${INSTALLER_URL}")
cd /home/ec2-user
wget ${INSTALLER_URL}
echo "Install MetaDefender..."
sudo yum install -y ${INSTALLER_FILE}

echo "Update config file"

OMETASCAN_CONF='/etc/ometascan/ometascan.conf'
sudo echo "[internal]" >> ${OMETASCAN_CONF}
sudo echo "ignition_file_location=/etc/opswat/ometascan.ini" >> ${OMETASCAN_CONF}

sleep 1m

echo "Restart MetaDefender service"
sudo systemctl restart ometascan.service

echo "Remove artifacts/keys"
sudo rm -f /home/ec2-user/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys
