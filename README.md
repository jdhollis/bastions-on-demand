# Bastions on Demand

This is a fully functional example of how to create and destroy bastion instances on demand using ECS.

For an in-depth guide to this example, check out [Bastions on Demand](https://theconsultingcto.com/posts/bastions-on-demand) on my site.

## Preliminaries

Before you being, you will need to install:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Bundler](https://bundler.io)
- [Docker](https://www.docker.com)
- [jq](https://stedolan.github.io/jq/)
- [Leiningen](https://leiningen.org) 
- [Terraform](https://www.terraform.io)

Everything in this repo assumes use of the `default` AWS profile. You can easily override that assumption with the `AWS_PROFILE` environment variable.

You can configure your credentials with [`aws configure`](https://docs.aws.amazon.com/cli/latest/reference/configure/).

You will also need to upload your public SSH key to your IAM user using either the AWS Console or the CLI (if you haven't already).

## Setup

If you haven't previously configured a CloudWatch role for API Gateway, then use the [`api-gateway-logger`](https://github.com/jdhollis/bastions-on-demand/tree/master/api-gateway-logger) module to do so now:

```bash
cd api-gateway-logger
terraform init
terraform plan -out plan
terraform apply plan && rm plan
cd ..
``` 

This is a global account setting, so you should only have to do it once. Note that destroying that module's resources with Terraform will remove the role, but it will not blank the CloudWatch role setting for API Gateway.

Now we're ready to create the service.

```bash
terraform init
./service/bin/build.sh  # Build the Lambda functions
terraform apply plan && rm plan
```

Once the Terraform successfully applies, fire up Docker (if you don't already have it running). Then, build and push the bastion image with:

```bash
./bastion/bin/login.sh  # Log into ECR
./bastion/bin/build.sh  # Build & tag the Docker image
./bastion/bin/push.sh   # Push the tagged image to ECR
```

Finally, we need to make certain the necessary Ruby dependencies are installed:

```bash
cd service
bundle
cd ..
```

You should now be able to create and destroy bastions with:

```bash
./service/bin/create-bastion.sh
./service/bin/destroy-bastion.sh
```

Once a bastion is running, you'll find its IP address in `service/.bastion-ip`.

You can `ssh` into the bastion with:

```bash
ssh ops@$(cat service/.bastion-ip)
```
