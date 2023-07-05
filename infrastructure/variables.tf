variable "region" {
  type        = string
  description = "region"
  default     = "eu-west-1"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "172.18.0.0/24"
}

variable "availability_zones" {
  type        = list(string)
  description = "availability_zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnets CIDR"
  default     = ["172.18.0.0/27", "172.18.0.32/27", "172.18.0.64/27"]
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnets CIDR"
  default     = ["172.18.0.96/27", "172.18.0.128/27", "172.18.0.160/27"]
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
  default     = "cluster"
}

variable "repository" {
  type        = string
  description = "ECR repository"
  default     = "python-api"
}

variable "max_image_count" {
  type        = number
  description = "Maximum number of images in ECR repository"
  default     = 10
}

variable "ecs_service_desired_count" {
  type        = number
  description = "ECS service desired count"
  default     = 0
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 5000
}
