terraform {

}

provider "aws" {
  region = "eu-central-1"
}

module "service" {
  source         = "./modules/services"
  service_name   = "lp-be-charging-service"
  service_port   = 32800
  jobrunr_port   = 32802
  cpu            = 512
  memory         = 2048
  lb-cluster     = var.lb-cluster
  dns_domain     = var.dns_domain
  zone_id        = var.zone_id
  listener_arn   = var.listener_arn
  desired_count  = var.desired_count
  aws_account_id = var.aws_account_id
  subnet1        = var.subnet1
  subnet2        = var.subnet2
  subnet3        = var.subnet3
  ecs_sg         = var.ecs_sg
}