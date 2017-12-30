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
    key            = "terraform.tfstate"
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
  source = "github.com/Originate/exosphere.git//terraform//aws?ref=30894145"

  name              = "space-tweet"
  env               = "${var.env}"
  external_dns_name = "${var.application_url}"
  key_name          = "${var.key_name}"
  log_bucket_prefix = "${var.aws_account_id}-space-tweet-${var.env}"
}

variable "exosphere-tweets-service_env_vars" {
  default = "[]"
}

variable "exosphere-tweets-service_docker_image" {}

module "exosphere-tweets-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//worker-service?ref=30894145"

  name = "exosphere-tweets-service"

  cluster_id            = "${module.aws.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.exosphere-tweets-service_docker_image}"
  env                   = "${var.env}"
  environment_variables = "${var.exosphere-tweets-service_env_vars}"
  memory_reservation    = "500"
  region                = "${module.aws.region}"
}

variable "exosphere-users-service_env_vars" {
  default = "[]"
}

variable "exosphere-users-service_docker_image" {}

module "exosphere-users-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//worker-service?ref=30894145"

  name = "exosphere-users-service"

  cluster_id            = "${module.aws.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.exosphere-users-service_docker_image}"
  env                   = "${var.env}"
  environment_variables = "${var.exosphere-users-service_env_vars}"
  memory_reservation    = "500"
  region                = "${module.aws.region}"
}

variable "space-tweet-web-service_env_vars" {
  default = "[]"
}

variable "space-tweet-web-service_docker_image" {}

variable "space-tweet-web-service_url" {}

module "space-tweet-web-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//public-service?ref=30894145"

  name = "space-tweet-web-service"

  alb_security_group    = "${module.aws.external_alb_security_group}"
  alb_subnet_ids        = ["${module.aws.public_subnet_ids}"]
  cluster_id            = "${module.aws.ecs_cluster_id}"
  container_port        = "3000"
  cpu                   = "128"
  desired_count         = 1
  docker_image          = "${var.space-tweet-web-service_docker_image}"
  ecs_role_arn          = "${module.aws.ecs_service_iam_role_arn}"
  env                   = "${var.env}"
  environment_variables = "${var.space-tweet-web-service_env_vars}"
  external_dns_name     = "${var.space-tweet-web-service_url}"
  external_zone_id      = "${module.aws.external_zone_id}"
  health_check_endpoint = "/"
  internal_dns_name     = "space-tweet-web-service"
  internal_zone_id      = "${module.aws.internal_zone_id}"
  log_bucket            = "${module.aws.log_bucket_id}"
  memory_reservation    = "128"
  region                = "${module.aws.region}"
  ssl_certificate_arn   = "${var.aws_ssl_certificate_arn}"
  vpc_id                = "${module.aws.vpc_id}"
}

