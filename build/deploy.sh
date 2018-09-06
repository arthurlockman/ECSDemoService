#!/usr/bin/env bash

# Configuration Parameters
STACK_NAME=ecs-demo
CLOUD_FORMATION_BUCKET_NAME=ecs-demo-cloudformation
REPOSITORY_NAME=ecs-demo-service
AWS_PROFILE=ecs-demo
SERVICE_VERSION=$(awk -F '[<>]' '/Version/{print $3}' ./ECSDemoService.csproj)

# Output Colors
BLACK="\033[0;30m"        # Black
RED="\033[0;31m"          # Red
GREEN="\033[0;32m"        # Green
YELLOW="\033[0;33m"       # Yellow
BLUE="\033[0;34m"         # Blue
PURPLE="\033[0;35m"       # Purple
CYAN="\033[0;36m"         # Cyan
WHITE="\033[0;37m"        # White
NC='\033[0m'              # No Color

# Validate CloudFormation templates
echo -e "${CYAN}Validating AWS CloudFormation templates...${NC}"
ERROR_COUNT=0;
# Loop through the YAML templates in this repository
for TEMPLATE in $(find . -name '*.yaml'); do

    # Validate the template with CloudFormation
    ERRORS=$(aws cloudformation validate-template --template-body file://${TEMPLATE} 2>&1 >/dev/null --profile ${AWS_PROFILE});
    if [ "$?" -gt "0" ]; then
        ((ERROR_COUNT++));
        echo -e "${RED}[fail] $TEMPLATE: $ERRORS${NC}";
    else
        echo -e "${GREEN}[pass] $TEMPLATE${NC}";
    fi;

done;

echo -e "${CYAN}$ERROR_COUNT template validation error(s)${NC}";
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}Error validating CloudFormation templates${NC}"
    exit 1;
fi

# Create CloudFormation bucket
if aws s3 ls "s3://${CLOUD_FORMATION_BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'
then
    echo -e "\n\n${CYAN}Creating S3 CloudFormation bucket since it does not exist...${NC}"
    aws s3api create-bucket --bucket ${CLOUD_FORMATION_BUCKET_NAME} --region us-east-1 --profile ${AWS_PROFILE}
fi
echo -e "${GREEN}Bucket created successfully.${NC}"

# Upload all CloudFormation templates to S3
echo -e "\n\n${CYAN}Uploading CloudFormation Templates to S3...${NC}"
aws s3 cp ./aws/ s3://${CLOUD_FORMATION_BUCKET_NAME} --recursive --profile ${AWS_PROFILE}
if [ $? -ne 0 ]; then
    echo -e "${RED}Error uploading CloudFormation Templates to S3${NC}"
    exit 1
fi
echo -e "${GREEN}CloudFormation templates uploaded successfully.${NC}"

# Create ECR repository with CloudFormation
echo -e "\n\n${CYAN}Creating ECR repository with CloudFormation...${NC}"
aws cloudformation deploy --stack-name ${STACK_NAME}-ECR --template-file ./aws/ecr.yaml --parameter-overrides RepositoryName=${REPOSITORY_NAME} --profile ${AWS_PROFILE} --no-fail-on-empty-changeset
if [ $? -ne 0 ]; then
    echo -e "${RED}Error deploying ECR repository CloudFormation stack${NC}"
    exit 1
fi

# Capture ECR URL for deploying Docker image
ECR_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME}-ECR --profile ${AWS_PROFILE} --query 'Stacks[0].Outputs[0].OutputValue')
ECR_URL="${ECR_URL%\"}" # Strip trailing quote
ECR_URL="${ECR_URL#\"}" # Strip prefixing quote
echo -e "${GREEN}Deployed ECR repository: ${ECR_URL}${NC}"

# Build docker image, and tag it with the proper ECR tag
echo -e "\n\n${CYAN}Building and tagging Docker image...${NC}"
echo Service Version ${SERVICE_VERSION}
docker build -t ${ECR_URL}:${SERVICE_VERSION} .
if [ $? -ne 0 ]; then
    echo -e "${RED}Error building Docker image${NC}"
    exit 1
fi
echo -e "${GREEN}Successfully built Docker image.${NC}"

# Push the docker image to ECR
echo -e "\n\n${CYAN}Pushing Docker image...${NC}"
$(aws ecr get-login --profile ${AWS_PROFILE} | sed 's/-e none//g')
docker push ${ECR_URL}
if [ $? -ne 0 ]; then
    echo -e "${RED}Error pushing Docker image to ECR${NC}"
    exit 1
fi
echo -e "${GREEN}Docker image version ${SERVICE_VERSION} pushed to ECR.${NC}"

# Deploy the CloudFormation stack
echo -e "\n\n${CYAN}Deploying CloudFormation stack...${NC}"
aws cloudformation deploy --stack-name ${STACK_NAME} --template-file ./aws/master.yaml --parameter-overrides ECRUrl=${ECR_URL} ServiceVersion=${SERVICE_VERSION} CloudFormationBucket=${CLOUD_FORMATION_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM --profile ${AWS_PROFILE} --no-fail-on-empty-changeset
if [ $? -ne 0 ]; then
    echo -e "${RED}Error deploying CloudFormation stack${NC}"
    exit 1
fi
echo -e "${GREEN}Service stack deployed successfully.${NC}"

# Capture CloudFormation stack details
SERVICE_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --profile ${AWS_PROFILE} --query 'Stacks[0].Outputs[0].OutputValue')

# Print out the service URL
echo -e "\n\n${GREEN}Complete! Visit your service at ${SERVICE_URL}${NC}"
