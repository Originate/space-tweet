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
    key            = "services.tfstate"
    dynamodb_table = "TerraformLocks"
  }
}

provider "aws" {
  version = "0.1.4"

  region              = "${var.aws_region}"
  profile             = "${var.aws_profile}"
  allowed_account_ids = ["${var.aws_account_id}"]
}

data "terraform_remote_state" "main_infrastructure" {
  backend = "s3"
  config {
    key            = "${var.aws_account_id}-space-tweet-${var.env}-terraform/infrastructure.tfstate"
    dynamodb_table = "TerraformLocks"
    region         = "${var.aws_region}"
    profile        = "${var.aws_profile}"
  }
}

variable "space-tweet-web-service_env_vars" {
  default = "[]"
}

variable "space-tweet-web-service_docker_image" {}

variable "space-tweet-web-service_url" {}

module "space-tweet-web-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//public-service?ref=fc9af4a1"

  name = "space-tweet-web-service"

  alb_security_group    = "${data.terraform_remote_state.main_infrastructure.external_alb_security_group}"
  alb_subnet_ids        = ["${data.terraform_remote_state.main_infrastructure.public_subnet_ids}"]
  cluster_id            = "${data.terraform_remote_state.main_infrastructure.ecs_cluster_id}"
  container_port        = "3000"
  cpu                   = "128"
  desired_count         = 1
  docker_image          = "${var.space-tweet-web-service_docker_image}"
  ecs_role_arn          = "${data.terraform_remote_state.main_infrastructure.ecs_service_iam_role_arn}"
  env                   = "${var.env}"
  environment_variables = "${var.space-tweet-web-service_env_vars}"
  external_dns_name     = "${var.space-tweet-web-service_url}"
  external_zone_id      = "${data.terraform_remote_state.main_infrastructure.external_zone_id}"
  health_check_endpoint = "/"
  internal_dns_name     = "space-tweet-web-service"
  internal_zone_id      = "${data.terraform_remote_state.main_infrastructure.internal_zone_id}"
  log_bucket            = "${data.terraform_remote_state.main_infrastructure.log_bucket_id}"
  memory_reservation    = "128"
  region                = "${data.terraform_remote_state.main_infrastructure.region}"
  ssl_certificate_arn   = "${var.aws_ssl_certificate_arn}"
  vpc_id                = "${data.terraform_remote_state.main_infrastructure.vpc_id}"
}

variable "storage-service_env_vars" {
  default = "[]"
}

variable "storage-service_docker_image" {}

module "storage-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//worker-service?ref=fc9af4a1"

  name = "storage-service"

  cluster_id            = "${data.terraform_remote_state.main_infrastructure.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.storage-service_docker_image}"
  env                   = "${var.env}"
  environment_variables = "${var.storage-service_env_vars}"
  memory_reservation    = "500"
  region                = "${data.terraform_remote_state.main_infrastructure.region}"
}
