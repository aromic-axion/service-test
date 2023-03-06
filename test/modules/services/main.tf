data "aws_ssm_parameter" "version" {
  name = "/${var.service_name}/version"
}

data "aws_ssm_parameter" "port" {
  name = "/${var.service_name}/port"
}

resource "aws_ecs_task_definition" "service-task" {
  family                   = "t-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"

  lifecycle {
    create_before_destroy = true
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  cpu    = 512
  memory = 2048

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = "364952602419.dkr.ecr.${var.aws_region}.amazonaws.com/${var.service_name}:${data.aws_ssm_parameter.version.value}"
      essential = true

      secrets = [
        { "name" : "elli.api-key", "valueFrom" : "/${var.service_name}/elli.api-key" }
      ]

      portMappings = [
        {
          containerPort = var.service_port
          hostPort      = var.service_port
        },
        {
          containerPort = var.jobrunr_port
          hostPort      = var.jobrunr_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service-log-group.name
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                              = "s-${var.service_name}"
  cluster                           = "arn:aws:ecs:${var.aws_region}:${var.aws_account_id}:cluster/${var.cluster_name}"
  task_definition                   = aws_ecs_task_definition.service-task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 1000

  lifecycle {
    create_before_destroy = true
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = ["${var.ecs_sg}"]
    subnets          = ["${var.subnet1}", "${var.subnet2}", "${var.subnet3}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target-group.arn
    container_name   = var.service_name
    container_port   = var.service_port
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target-group2.arn
    container_name   = var.service_name
    container_port   = var.jobrunr_port
  }
  depends_on = [aws_lb_listener_rule.listener-rule]
}

resource "aws_lb_target_group" "target-group" {
  name        = "ecs-${var.service_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    port                = var.service_port
    path                = "/actuator/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "target-group2" {
  name                 = "ecs-${var.service_name}-jr"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 5
  health_check {
    interval            = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 4
    port                = var.jobrunr_port
    path                = "/dashboard/overview"
  }
}

resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = var.listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
  condition {
    host_header {
      values = ["${var.service_name}.${var.dns_domain}"]
    }
  }
}

resource "aws_lb_listener_rule" "listener-rule2" {
  listener_arn = var.listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group2.arn
  }
  condition {
    host_header {
      values = ["${var.service_name}-jobrunr.${var.dns_domain}"]
    }
  }
}

resource "aws_route53_record" "r53-entry" {
  zone_id = var.zone_id
  name    = "${var.service_name}.${var.dns_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${var.lb-cluster}.${var.aws_region}.elb.amazonaws.com"]
}

resource "aws_route53_record" "r53-entry2" {
  zone_id = var.zone_id
  name    = "${var.service_name}-jobrunr.${var.dns_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${var.lb-cluster}.${var.aws_region}.elb.amazonaws.com"]
}

resource "aws_cloudwatch_log_group" "service-log-group" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30
}
