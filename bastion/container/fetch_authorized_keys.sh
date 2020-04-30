#!/bin/bash -e

set -e
set -u

source /etc/profile.d/authorized_keys_configuration.sh

sts_credentials=$(/usr/local/bin/aws sts assume-role \
  --role-arn "${ASSUME_ROLE_FOR_AUTHORIZED_KEYS}" \
  --role-session-name fetch-authorized-keys-for-bastion \
  --query '[Credentials.SessionToken,Credentials.AccessKeyId,Credentials.SecretAccessKey]' \
  --output text)

AWS_ACCESS_KEY_ID=$(echo "${sts_credentials}" | awk '{print $2}')
AWS_SECRET_ACCESS_KEY=$(echo "${sts_credentials}" | awk '{print $3}')
AWS_SESSION_TOKEN=$(echo "${sts_credentials}" | awk '{print $1}')
AWS_SECURITY_TOKEN=$(echo "${sts_credentials}" | awk '{print $1}')
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN

/usr/local/bin/aws iam list-ssh-public-keys --user-name "$USER_NAME" --query "SSHPublicKeys[?Status == 'Active'].[SSHPublicKeyId]" --output text | while read -r key_id; do
  /usr/local/bin/aws iam get-ssh-public-key --user-name "$USER_NAME" --ssh-public-key-id "$key_id" --encoding SSH --query "SSHPublicKey.SSHPublicKeyBody" --output text
done
