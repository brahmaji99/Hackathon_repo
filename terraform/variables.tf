variable "aws_region" {
  default = "eu-north-1"
}

variable "project_name" {
  default = "ecs-app"
}

variable "ecr_image_uri" {
  description = "ECR image URI with tag"
}

variable "container_port" {
  default = 80
}

variable "cpu" {
  default = 256
}

variable "memory" {
  default = 512
}
