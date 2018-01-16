variable "aws_profile" {
  default = "default"
}

variable "aws_region" {}

variable "aws_account_id" {}

variable "aws_ssl_certificate_arn" {}

variable "application_url" {}

variable "env" {}

terraform {
  required_version = "= 0.11.0"

  backend "s3" {
    key            = "infrastructure.tfstate"
    dynamodb_table = "TerraformLocks"
  }
}

provider "aws" {
  version = "0.1.4"

  region              = "${var.aws_region}"
  profile             = "${var.aws_profile}"
  allowed_account_ids = ["${var.aws_account_id}"]
}

variable "key_name" {
  default = ""
}

module "aws" {
  source = "github.com/Originate/exosphere.git//terraform//aws?ref=89c45cc0"

  name              = "space-tweet"
  env               = "${var.env}"
  external_dns_name = "${var.application_url}"
  key_name          = "${var.key_name}"
  log_bucket_prefix = "${var.aws_account_id}-space-tweet-${var.env}"
}

output "availability_zones" {
  description = "List of AZs"
  value       = "${module.aws.availability_zones}"
}

output "bastion_security_group" {
  description = "ID of the security group of the bastion hosts"
  value       = "${module.aws.bastion_security_group}"
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = "${module.aws.ecs_cluster_id}"
}

output "ecs_cluster_security_group" {
  description = "ID of the security group of the ECS cluster instances"
  value       = "${module.aws.ecs_cluster_security_group}"
}

output "ecs_service_iam_role_arn" {
  description = "ARN of ECS service IAM role passed to each service module"
  value       = "${module.aws.ecs_service_iam_role_arn}"
}

output "external_alb_security_group" {
  description = "ID of the external ALB security group"
  value       = "${module.aws.external_alb_security_group}"
}

output "external_zone_id" {
  description = "The Route53 external zone ID"
  value       = "${module.aws.external_zone_id}"
}

output "internal_alb_security_group" {
  description = "ID of the internal ALB security group"
  value       = "${module.aws.internal_alb_security_group}"
}

output "internal_zone_id" {
  description = "The Route53 internal zone ID"
  value       = "${module.aws.internal_zone_id}"
}

output "log_bucket_id" {
  description = "S3 bucket id of load balancer logs"
  value       = "${module.aws.log_bucket_id}"
}

output "public_subnet_ids" {
  description = "ID's of the public subnets"
  value       = ["${module.aws.public_subnet_ids}"]
}

output "private_subnet_ids" {
  description = "ID's of the private subnets"
  value       = ["${module.aws.private_subnet_ids}"]
}

output "region" {
  description = "Region of the environment, for example, us-west-2"
  value       = "${module.aws.region}"
}

output "vpc_id" {
  value = "${module.aws.vpc_id}"
}

module "exocom_cluster" {
  source = "github.com/Originate/exosphere.git//remote-dependency-templates//exocom//modules//exocom-cluster?ref=89c45cc0"

  availability_zones      = "${module.aws.availability_zones}"
  env                     = "${var.env}"
  internal_hosted_zone_id = "${module.aws.internal_zone_id}"
  instance_type           = "t2.micro"
  key_name                = "${var.key_name}"
  name                    = "exocom"
  region                  = "${module.aws.region}"

  bastion_security_group = ["${module.aws.bastion_security_group}"]

  ecs_cluster_security_groups = ["${module.aws.ecs_cluster_security_group}",
    "${module.aws.external_alb_security_group}",
  ]

  subnet_ids = "${module.aws.private_subnet_ids}"
  vpc_id     = "${module.aws.vpc_id}"
}

variable "exocom_env_vars" {
  default = ""
}

module "exocom_service" {
  source = "github.com/Originate/exosphere.git//remote-dependency-templates//exocom//modules//exocom-service?ref=89c45cc0"

  cluster_id            = "${module.exocom_cluster.cluster_id}"
  cpu_units             = "128"
  docker_image          = "originate/exocom:0.27.0"
  env                   = "${var.env}"
  environment_variables = "${var.exocom_env_vars}"
  memory_reservation    = "128"
  name                  = "exocom"
  region                = "${module.aws.region}"
}
