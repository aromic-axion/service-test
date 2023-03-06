variable "aws_region" { default = "eu-central-1" }
variable "environment" { default = null }
variable "vpc_id" { default = null }
variable "zone_id" { default = null }
variable "listener_arn" { default = null }
variable "ecs_sg" { default = null }

variable "dns_domain" { default = null }
variable "dns_domain2" { default = null }
variable "vpn" { default = false }
variable "aws_account_id" { default = null }
variable "subnet1" { default = null }
variable "subnet2" { default = null }
variable "subnet3" { default = null }

variable "desired_count" { default = 1 }

variable "cluster_name" {
  default     = "null"
  type        = string
  description = "Name of an ECS cluster"
}

variable "lb-cluster" {
  default     = null
  type        = string
  description = "Name of load balancer cluster"
}