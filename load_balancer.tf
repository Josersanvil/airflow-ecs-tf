resource "aws_acm_certificate" "airflow_domain" {
  count       = var.route_53_domain_name != null ? 1 : 0
  domain      = var.airflow_web_subomain != "" ? "${var.airflow_web_subomain}.${var.route_53_domain_name}" : var.route_53_domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb" "airflow-alb" {
  name                       = "airflow-alb-${local.deployment_id}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.airflow_web_security_group.id]
  subnets                    = local.airflow_vpc_subnets_ids
  enable_deletion_protection = false
}

resource "aws_alb_listener" "http_redirect" {
  count             = var.route_53_domain_name != null ? 1 : 0
  load_balancer_arn = aws_lb.airflow-alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "http_forward" {
  count             = var.route_53_domain_name != null ? 0 : 1
  load_balancer_arn = aws_lb.airflow-alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.airflow_web_target.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "https_forward" {
  count             = var.route_53_domain_name != null ? 1 : 0
  load_balancer_arn = aws_lb.airflow-alb.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.airflow_domain[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.airflow_web_target.id
    type             = "forward"
  }
}


resource "aws_lb_target_group" "airflow_web_target" {
  name = "airflow-web-target-${local.deployment_id}"

  health_check {
    enabled             = "true"
    healthy_threshold   = "5"
    interval            = "30"
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "2"
  }

  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = "80"
  protocol                      = "HTTP"
  protocol_version              = "HTTP1"
  slow_start                    = "180"

  stickiness {
    cookie_duration = "86400"
    enabled         = "false"
    type            = "lb_cookie"
  }

  target_type = "ip"
  vpc_id      = local.airflow_vpc_id

  depends_on = [
    aws_lb.airflow-alb
  ]
}

# Add dns record for the load balancer:

data "aws_route53_zone" "airflow-domain" {
  count = var.route_53_domain_name != null ? 1 : 0
  name  = var.route_53_domain_name
}

resource "aws_route53_record" "airflow-record" {
  count = var.route_53_domain_name != null ? 1 : 0
  alias {
    evaluate_target_health = "true"
    name                   = aws_lb.airflow-alb.dns_name
    zone_id                = aws_lb.airflow-alb.zone_id
  }

  name    = var.airflow_web_subomain != "" ? "${var.airflow_web_subomain}.${var.route_53_domain_name}" : var.route_53_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.airflow-domain[0].zone_id
}
