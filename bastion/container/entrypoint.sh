#!/bin/sh

set -e
set -u

echo "Creating host keys..."
ssh-keygen -A

echo "Exporting global environment..."

echo "export AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" > /etc/profile.d/authorized_keys_configuration.sh
echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> /etc/profile.d/authorized_keys_configuration.sh
echo "export AWS_EXECUTION_ENV=$AWS_EXECUTION_ENV" >> /etc/profile.d/authorized_keys_configuration.sh
echo "export AWS_REGION=$AWS_REGION" >> /etc/profile.d/authorized_keys_configuration.sh
echo "export ECS_CONTAINER_METADATA_URI=$ECS_CONTAINER_METADATA_URI" >> /etc/profile.d/authorized_keys_configuration.sh
echo "export ASSUME_ROLE_FOR_AUTHORIZED_KEYS=$ASSUME_ROLE_FOR_AUTHORIZED_KEYS" >> /etc/profile.d/authorized_keys_configuration.sh
echo "export USER_NAME=$USER_NAME" >> /etc/profile.d/authorized_keys_configuration.sh

chmod +x /etc/profile.d/authorized_keys_configuration.sh

exec /usr/sbin/sshd -D -e "$@"
