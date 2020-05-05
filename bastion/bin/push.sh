#!/usr/bin/env bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../.." # Start from a consistent working directory

echo "Fetching account ID..."
account_id=$(aws sts get-caller-identity --query '[Account]' --output text)

echo "Fetching bastion region..."
region=$(terraform output region)

echo "Pushing image..."
docker push ${account_id}.dkr.ecr.${region}.amazonaws.com/bastion

echo "Done"
