#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../.." # Start from a consistent working directory

echo "Fetching bastion service endpoint..."
invoke_url=$(terraform output bastion_service_endpoint)

if [[ -z ${invoke_url} ]]
then
  echo "No bastion service found." >&2
  exit 1
fi

echo "Creating bastion..."
INVOKE_URL=${invoke_url} cd service && bundle exec ruby create.rb | jq -r .ip > .bastion-ip

if [[ $(cat .bastion-ip) == "null" ]]
then
  rm .bastion-ip
  echo "No IP address returned. Probably just AWS being slow. Try rerunning this script." >&2
  exit 1
else
  echo "Done"
  cat .bastion-ip
fi
