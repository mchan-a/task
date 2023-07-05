#!/usr/bin/env bash

DOCKER_IMAGE_NAME=python-api
ECS_CLUSTER=cluster
ECS_SERVICE=service
ECS_SERVICE_DESIRED_COUNT=1
INFRASTRUCTURE_FOLDER=infrastructure
LOAD_BALANCER_NAME=ecs-alb
PYTHON_APPLICATION_REPOSITORY=https://github.com/mransbro/python-api.git
REGION=eu-west-1

function confirm {
  echo -e "\n"
  read -p "Please confirm that you are happy to continue (yes/no): " -r REPLY

  if [ ${REPLY,,} != "yes" ]
  then
    exit 1
  fi
}

function check_command {
if ! command -v ${1} > /dev/null
then
  echo "${1} not installed!"
  exit 1
fi
}

function clone_python_repository {
  cd -
  FOLDER=$(basename ${PYTHON_APPLICATION_REPOSITORY} .git)

  if [ ! -d "./${FOLDER}" ]
  then
    git clone ${PYTHON_APPLICATION_REPOSITORY}
  fi
}

function terraform_init_and_plan {
  cd ${INFRASTRUCTURE_FOLDER}
  terraform init
  terraform plan
}

function terraform_apply {
  echo -e "\n"
  read -p "Please confirm that you are happy to continue with terraform apply -auto-approve (yes/no): " -r REPLY

  if [ ${REPLY,,} != "yes" ]
  then
    exit 1
  fi

  terraform apply -auto-approve

  if [ $? -ne 0 ]
  then
    echo "terraform apply error!"
    exit 1
  fi
}

function docker_build {
  echo -e "\nBuild Docker image"
  cd ${FOLDER}
  docker build -t ${DOCKER_IMAGE_NAME} .
}

function get_aws_account_number {
  ACCOUNT_NUMBER=$(aws sts get-caller-identity --output text --query Account)

  REGISTRY=${ACCOUNT_NUMBER}.dkr.ecr.${REGION}.amazonaws.com
}

function docker_push {
  echo -e "\nPush Docker image"
  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${REGISTRY}

  URI=${REGISTRY}/${DOCKER_IMAGE_NAME}:latest
  docker tag ${DOCKER_IMAGE_NAME}:latest ${URI}
  docker push ${URI}

  if [ $? -ne 0 ]
  then
    echo "error pushing Docker image to ECR"
    exit 1
  fi
}

function update_ecs_service_desired_count {
  echo -e "\nChange ECS service desired count"
  aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --desired-count ${ECS_SERVICE_DESIRED_COUNT} --output text
}

function get_load_balancer {
  CREATED_LOAD_BALANCER=$(aws elbv2 describe-load-balancers --query LoadBalancers[*].DNSName --output text | grep -i ${LOAD_BALANCER_NAME})
}

function action_curl {
  echo -e "\nPlease wait a couple of minutes for the ECS task to be in running status before actioning any curl commands"

  echo -e "\n1 curl ${CREATED_LOAD_BALANCER}/\n2 curl ${CREATED_LOAD_BALANCER}/2\n3 curl -X POST ${CREATED_LOAD_BALANCER}\n4 exit\n"
  read -p "Option: " -r OPTION

  case "${OPTION}" in
  1)
    curl ${CREATED_LOAD_BALANCER}
    action_curl
    ;;
  2)
    curl ${CREATED_LOAD_BALANCER}/2
    action_curl
    ;;
  3)
    curl -X POST ${CREATED_LOAD_BALANCER}
    action_curl
    ;;
  4)
    exit 1
    ;;
  *)
    echo "1, 2, 3 or 4 only!"
    exit 1
    ;;
  esac
}

function main {
  echo "Task"
  echo -e "----\n"
  echo -e "This script will run Terraform that creates the following:\n"
  echo -e "-VPC"
  echo -e "-Internet Gateway"
  echo -e "-Private and public subnets"
  echo -e "-Route tables"
  echo -e "-NAT Gateway"
  echo -e "-Security groups"
  echo -e "-ALB"
  echo -e "-ECR repository"
  echo -e "-IAM role"
  echo -e "-ECS cluster"
  echo -e "-ECS service"
  echo -e "-ECS task definition"
  echo -e "-CloudWatch log group\n"
  echo -e "Normally we would reference an already created S3 bucket to hold Terraform state and DynamoDB table in our backend.tf file.\n"
  echo -e "It is also assumed that Terraform, Docker, Git and AWS CLI are installed and AWS credentials are set.\n"
  echo -e "It will then apply the Terraform, build Docker image, push Docker image, change ECS service desired count to 1 and then finally show you the created load balancer."

  confirm
  check_command terraform
  check_command docker
  check_command git
  check_command aws
  terraform_init_and_plan
  terraform_apply
  clone_python_repository
  docker_build
  get_aws_account_number
  docker_push
  update_ecs_service_desired_count
  get_load_balancer
  action_curl
}

main
