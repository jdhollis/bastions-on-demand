#!/usr/bin/env bash

region=${1:-us-east-1}
account_id=$(aws sts get-caller-identity --region ${region} --query '[Account]' --output text)

docker build -t ${account_id}.dkr.ecr.${region}.amazonaws.com/bastion ./container
