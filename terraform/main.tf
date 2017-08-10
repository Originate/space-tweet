terraform {
  required_version = "= 0.9.11"

  backend "s3" {
    bucket     = "space-tweet-terraform"
    key        = "dev/terraform.tfstate"
    region     = "us-west-2"
    lock_table = "TerraformLocks"
  }
}

provider "aws" {
  region              = "${var.region}"
  profile             = "${var.aws_profile}"
  allowed_account_ids = ["${var.account_id}"]
}

module "aws" {
  source = "./aws"

  name     = "space-tweet"
  env      = "production"
  key_name = "${var.key_name}"
}

module "space-tweet-web-service" {
  source = "./aws/public-service"

  name = "space-tweet-web-service"

  alb_security_group    = ["${module.aws.external_alb_security_group}"]
  alb_subnet_ids        = ["${module.aws.public_subnet_ids}"]
  cluster_id            = "${module.aws.cluster_id}"
  command               = ["node_modules/.bin/lsc","app"]
  container_port        = "3000"
  cpu                   = "128"
  desired_count         = 1
  docker_image          = "518695917306.dkr.ecr.us-west-2.amazonaws.com/tmp_space-tweet-web-service:0.0.1"
  ecs_role_arn          = "${module.aws.ecs_service_iam_role_arn}"
  env                   = "production"
  external_dns_name     = "spacetweet.originate.com"
  external_zone_id      = "${var.hosted_zone_id}"
  health_check_endpoint = "/"
  internal_dns_name     = "${module.aws.internal_dns_name}"
  internal_zone_id      = "${module.aws.internal_hosted_zone_id}"
  log_bucket            = "${module.aws.log_bucket_id}"
  memory                = "128"
  region                = "${var.region}"
  ssl_certificate_arn   = "${var.ssl_certificate_arn}"
  vpc_id                = "${module.aws.vpc_id}"
}

module "exosphere-tweets-service" {
  source = "./aws/worker-service"

  name = "exosphere-tweets-service"

  cluster_id    = "${module.aws.cluster_id}"
  command       = ["node_modules/exoservice/bin/exo-js"]
  cpu           = "100"
  desired_count = 1
  docker_image  = "518695917306.dkr.ecr.us-west-2.amazonaws.com/tmp_exosphere-tweets-service:0.0.1"
  env           = "production"
  memory        = "500"
  region        = "${var.region}"
}

module "exosphere-users-service" {
  source = "./aws/worker-service"

  name = "exosphere-users-service"

  cluster_id    = "${module.aws.cluster_id}"
  command       = ["node_modules/exoservice/bin/exo-js"]
  cpu           = "100"
  desired_count = 1
  docker_image  = "518695917306.dkr.ecr.us-west-2.amazonaws.com/tmp_exosphere-users-service:0.0.1"
  env           = "production"
  memory        = "500"
  region        = "${var.region}"
}

module "exocom_cluster" {
  source = "./aws/custom/exocom/exocom-cluster"

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

module "exocom_service" {
  source = "./aws/custom/exocom/exocom-service"

  cluster_id            = "${module.exocom_cluster.cluster_id}"
  command               = ["bin/exocom"]
  container_port        = "3100"
  cpu_units             = "128"
  docker_image          = "518695917306.dkr.ecr.us-west-2.amazonaws.com/originate/exocom:0.21.8"
  env                   = "production"
  environment_variables = {
    ROLE = "exocom"
  }
  memory_reservation    = "128"
  name                  = "exocom"
  region                = "${module.aws.region}"
}
