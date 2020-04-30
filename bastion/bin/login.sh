#!/usr/bin/env bash

profile=${1}
region=${2:-us-east-1}

account_id=$(aws sts get-caller-identity --region ${region} --profile ${profile} --query '[Account]' --output text)

aws ecr get-login-password \
  --profile ${profile} \
  --region ${region} \
| docker login \
    --username AWS \
    --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com
