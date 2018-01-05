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

variable "storage-service_env_vars" {
  default = "[]"
}

variable "storage-service_docker_image" {}

module "storage-service" {
  source = "github.com/Originate/exosphere.git//terraform//aws//worker-service?ref=30894145"

  name = "storage-service"

  cluster_id            = "${module.aws.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.storage-service_docker_image}"
  env                   = "${var.env}"
  environment_variables = "${var.storage-service_env_vars}"
  memory_reservation    = "500"
  region                = "${module.aws.region}"
}

module "exocom_cluster" {
  source = "github.com/Originate/exosphere.git//remote-dependency-templates//exocom//modules//exocom-cluster?ref=30894145"

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
  source = "github.com/Originate/exosphere.git//remote-dependency-templates//exocom//modules//exocom-service?ref=30894145"

  cluster_id            = "${module.exocom_cluster.cluster_id}"
  cpu_units             = "128"
  docker_image          = "originate/exocom:0.27.0"
  env                   = "${var.env}"
  environment_variables = "${var.exocom_env_vars}"
  memory_reservation    = "128"
  name                  = "exocom"
  region                = "${module.aws.region}"
}
