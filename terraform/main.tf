variable "aws_profile" {
  default = "default"
}

terraform {
  required_version = ">= 0.10.0"

  backend "s3" {
    bucket         = "518695917306-space-tweet-terraform"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "TerraformLocks"
  }
}

provider "aws" {
  version = "0.1.4"

  region              = "us-west-2"
  profile             = "${var.aws_profile}"
  allowed_account_ids = ["518695917306"]
}

variable "key_name" {
  default = ""
}

module "aws" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws?ref=f456f3f4"

  name              = "space-tweet"
  env               = "production"
  external_dns_name = "spacetweet.originate.com"
  key_name          = "${var.key_name}"
}

variable "exosphere-tweets-service_env_vars" {
  default = "[]"
}

variable "exosphere-tweets-service_docker_image" {}

module "exosphere-tweets-service" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws//worker-service?ref=f456f3f4"

  name = "exosphere-tweets-service"

  cluster_id            = "${module.aws.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.exosphere-tweets-service_docker_image}"
  env                   = "production"
  environment_variables = "${var.exosphere-tweets-service_env_vars}"
  memory_reservation    = "500"
  region                = "${module.aws.region}"
}

variable "exosphere-users-service_env_vars" {
  default = "[]"
}

variable "exosphere-users-service_docker_image" {}

module "exosphere-users-service" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws//worker-service?ref=f456f3f4"

  name = "exosphere-users-service"

  cluster_id            = "${module.aws.ecs_cluster_id}"
  cpu                   = "100"
  desired_count         = 1
  docker_image          = "${var.exosphere-users-service_docker_image}"
  env                   = "production"
  environment_variables = "${var.exosphere-users-service_env_vars}"
  memory_reservation    = "500"
  region                = "${module.aws.region}"
}

variable "space-tweet-web-service_env_vars" {
  default = "[]"
}

variable "space-tweet-web-service_docker_image" {}

module "space-tweet-web-service" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws//public-service?ref=f456f3f4"

  name = "space-tweet-web-service"

  alb_security_group    = "${module.aws.external_alb_security_group}"
  alb_subnet_ids        = ["${module.aws.public_subnet_ids}"]
  cluster_id            = "${module.aws.ecs_cluster_id}"
  container_port        = "3000"
  cpu                   = "128"
  desired_count         = 1
  docker_image          = "${var.space-tweet-web-service_docker_image}"
  ecs_role_arn          = "${module.aws.ecs_service_iam_role_arn}"
  env                   = "production"
  environment_variables = "${var.space-tweet-web-service_env_vars}"
  external_dns_name     = "spacetweet.originate.com"
  external_zone_id      = "${module.aws.external_zone_id}"
  health_check_endpoint = "/"
  internal_dns_name     = "space-tweet-web-service"
  internal_zone_id      = "${module.aws.internal_zone_id}"
  log_bucket            = "${module.aws.log_bucket_id}"
  memory_reservation    = "128"
  region                = "${module.aws.region}"
  ssl_certificate_arn   = "arn:aws:acm:us-west-2:518695917306:certificate/c9a6be72-c6a3-4551-8e5b-53f5cfd89199"
  vpc_id                = "${module.aws.vpc_id}"
}

module "exocom_cluster" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws//dependencies//exocom//exocom-cluster?ref=f456f3f4"

  availability_zones          = "${module.aws.availability_zones}"
  env                         = "production"
  internal_hosted_zone_id     = "${module.aws.internal_zone_id}"
  instance_type               = "t2.micro"
  key_name                    = "${var.key_name}"
  name                        = "exocom"
  region                      = "${module.aws.region}"

  bastion_security_group      = ["${module.aws.bastion_security_group}"]

  ecs_cluster_security_groups = [ "${module.aws.ecs_cluster_security_group}",
    "${module.aws.external_alb_security_group}",
  ]

  subnet_ids                  = "${module.aws.private_subnet_ids}"
  vpc_id                      = "${module.aws.vpc_id}"
}

variable "exocom_env_vars" {
  default = ""
}

module "exocom_service" {
  source = "git@github.com:Originate/exosphere.git//src//terraform//modules//aws//dependencies//exocom//exocom-service?ref=f456f3f4"

  cluster_id            = "${module.exocom_cluster.cluster_id}"
  cpu_units             = "128"
  docker_image          = "518695917306.dkr.ecr.us-west-2.amazonaws.com/originate/exocom:0.26.3"
  env                   = "production"
  environment_variables = "${var.exocom_env_vars}"
  memory_reservation    = "128"
  name                  = "exocom"
  region                = "${module.aws.region}"
}
