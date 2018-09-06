# ECS Demo Service

This project is a demonstration of running a .NET Core service inside of [Amazon ECS](https://aws.amazon.com/ecs/).
The service is packaged into a Docker image and pushed to the Amazon Elastic Container Registry for deployment. The
project contains scripts to build and deploy this service using CloudFormation. 

## Prerequisites

In order to work on this service, you will need to install 
[.NET Core 2.1](https://www.microsoft.com/net/download/dotnet-core/2.1) or newer on your development machine (only if 
you want to use an IDE to make changes). You will also need to have [Docker](https://www.docker.com/get-started)
installed and running to be able to package the service for deployment.

## Building

To build the service, use Docker:

    docker build -t ecs-demo-service .

## Running

To run your built Docker container, use the following command:

    docker run -t ecs-demo-service -p 8080:80

Then you can connect to the service on `http://localhost:8080`.

## Deployment

If you want to deploy the service to Amazon ECS, you will first need to install the 
[AWS CLI](https://aws.amazon.com/cli/) on your local development computer. You will also need to set up your AWS account
in your `~/.aws/credentials` credential store. Make note of the name of the
[profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html) you configure. 

*Note: if you name the profile `ecs-demo`, you will not need to configure any parameters in the deployment script.*

### Permissions

Deployment is handled through CloudFormation. In order to deploy, make sure your user profile has the following
AWS managed policies attached to it:

* AmazonEC2FullAccess
* AWSLambdaFullAccess
* IAMFullAccess
* AutoScalingFullAccess
* AmazonEC2ContainerRegistryFullAccess
* AmazonS3FullAccess
* CloudWatchLogsFullAccess
* AmazonECS_FullAccess
* AmazonSNSFullAccess

Additionally, you will need to attach this inline policy to give access to CloudFormation:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "cloudformation:*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }

### Running Deployment

You will need to make a few changes in the `./build/deploy.sh` script if you used a different AWS profile name other
than `ecs-demo`, or if you wish to change the name of the CloudFormation stack. Lines 4 through 7 of the deployment 
script contain these variables. They are described below.

* `STACK_NAME` - the name of the CloudFormation stack to create
* `CLOUD_FORMATION_BUCKET_NAME` - The name of the bucket to upload the stack files to (will be created for you)
* `REPOSITORY_NAME` - The name of the ECR repository to use
* `AWS_PROFILE` - The name of the AWS profile to use to deploy

Once these are configured, you can deploy the stack by this commands in the project root:

    ./build/deploy.sh

This may take a while on the first deployment (10+ minutes). The script will print out the service URLs that you can use
to access your service once it is deployed.
