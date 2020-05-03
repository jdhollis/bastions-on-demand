#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../.." # Start from a consistent working directory

if [[ -f ".bastion-ip" ]]
then
  echo "Fetching bastion service endpoint..."
  invoke_url=$(terraform output bastion_service_endpoint)

  if [[ -z ${invoke_url} ]]
  then
    echo "No bastion service found." >&2
    exit 1
  fi

  echo "Destroying bastion..."
  INVOKE_URL=${invoke_url} bundle exec ruby destroy.rb && rm .bastion-ip
fi

echo "Done"
