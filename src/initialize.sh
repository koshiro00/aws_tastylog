#!/bin/bash
# ---------------------------------
# EC2 user data
# Autoscaling startup scripts.
# ---------------------------------
APP_NAME=tastylog
BUCKET_NAME=tastylog-dev-deploy-bucket-9zahho
CWD=/home/ec2-user

# Log output setting
LOGFILE="/var/log/initialize.log"
exec > "${LOGFILE}"
exec 2>&1

# Change current work directory
cd ${CWD}

# Get latest version number.
aws s3 cp s3://${BUCKET_NAME}/latest ${CWD}

# Get latest resources.
aws s3 cp s3://${BUCKET_NAME}/${APP_NAME}-app-$(cat ./latest).tar.gz ${CWD}

# Decompress tar.gz
rm -rf ${CWD}/${APP_NAME}
mkdir -p ${CWD}/${APP_NAME}
tar -zxvf "${CWD}/${APP_NAME}-app-$(cat ./latest).tar.gz" -C "${CWD}/${APP_NAME}"

# Move to application directory
sudo rm -rf /opt/${APP_NAME}
sudo mv ${CWD}/${APP_NAME} /opt/

# Create environment variables file from Parameter Store
echo "Creating environment variables file from Parameter Store..."
sudo bash -c "cat > /etc/params << EOF
MYSQL_HOST=\$(aws ssm get-parameter --name \"/tastylog/dev/app/MYSQL_HOST\" --query \"Parameter.Value\" --output text --region ap-northeast-1)
MYSQL_PORT=\$(aws ssm get-parameter --name \"/tastylog/dev/app/MYSQL_PORT\" --query \"Parameter.Value\" --output text --region ap-northeast-1)
MYSQL_DATABASE=\$(aws ssm get-parameter --name \"/tastylog/dev/app/MYSQL_DATABASE\" --query \"Parameter.Value\" --output text --region ap-northeast-1)
MYSQL_USERNAME=\$(aws ssm get-parameter --name \"/tastylog/dev/app/MYSQL_USERNAME\" --with-decryption --query \"Parameter.Value\" --output text --region ap-northeast-1)
MYSQL_PASSWORD=\$(aws ssm get-parameter --name \"/tastylog/dev/app/MYSQL_PASSWORD\" --with-decryption --query \"Parameter.Value\" --output text --region ap-northeast-1)
EOF"

# Reload systemd and enable service
sudo systemctl daemon-reload

# Boot application 
sudo systemctl enable tastylog
sudo systemctl start tastylog

echo "Application startup completed."