resource "aws_efs_file_system" "airflow_logs" {
  creation_token = "airflow_logs-${local.deployment_id}"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "airflow_logs-${local.deployment_id}"
  }
}

resource "aws_efs_file_system" "airflow_redis" {
  creation_token = "airflow_redis-${local.deployment_id}"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "airflow_redis-${local.deployment_id}"
  }
}

resource "aws_security_group" "Airflow_fs" {
  name        = "Airflow-${local.deployment_id}-fs-sg"
  description = "Allows inbound access in the VPC on TCP port 2049"
  vpc_id      = local.airflow_vpc_id

  ingress {
    description = "Allows inbound access from the VPC on TCP port 2049"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.airflow_vpc_cidr_block]
  }
}

resource "aws_efs_mount_target" "airflow_logs_fs" {
  for_each = toset(local.airflow_vpc_subnets_ids)

  file_system_id  = aws_efs_file_system.airflow_logs.id
  subnet_id       = each.key
  security_groups = [aws_security_group.Airflow_fs.id]
}

resource "aws_efs_mount_target" "airflow_redis_fs" {
  for_each = toset(local.airflow_vpc_subnets_ids)

  file_system_id  = aws_efs_file_system.airflow_redis.id
  subnet_id       = each.key
  security_groups = [aws_security_group.Airflow_fs.id]
}

resource "time_sleep" "wait_for_airflow_logs_efs_dns_propagation" {
  # Up to 90 seconds can elapse for the DNS records to propagate after creating a mount target
  depends_on      = [aws_efs_mount_target.airflow_logs_fs]
  create_duration = "90s"
}

resource "time_sleep" "wait_for_redis_efs_dns_propagation" {
  # Up to 90 seconds can elapse for the DNS records to propagate after creating a mount target
  depends_on      = [aws_efs_mount_target.airflow_redis_fs]
  create_duration = "90s"
}
