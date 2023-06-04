# All resources related to the Airflow metadata database.
# The database is not publicly accessible via the Internet. Only from the VPC.
# The database master user password is managed by AWS Secrets Manager.

# Create the database subnet group
resource "aws_db_subnet_group" "airflow_db_subnet_group" {
  name       = "airflow-db-subnet-group-${local.deployment_id}"
  subnet_ids = local.airflow_vpc_subnets_ids
}

# Database security group
resource "aws_security_group" "airflow_db_security_group" {
  name        = "airflow-db-sg-${local.deployment_id}"
  description = "Allows access to the database from the VPC on TCP port 5432 (postgres)"
  vpc_id      = local.airflow_vpc_id

  ingress {
    description = "Allows access to the database from the VPC on TCP port 5432 (postgres)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.airflow_vpc_cidr_block]
  }

  egress {
    description = "Allows outbound access anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }
}

# Create the database as an Aurora Serverless PostgreSQL database
resource "aws_rds_cluster" "airflow_db" {
  cluster_identifier              = "airflow-db-${local.deployment_id}"
  master_username                 = "postgres"
  db_subnet_group_name            = aws_db_subnet_group.airflow_db_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.airflow_db_security_group.id]
  backup_retention_period         = 7
  copy_tags_to_snapshot           = true
  database_name                   = "airflow"
  db_cluster_parameter_group_name = "default.aurora-postgresql13"
  deletion_protection             = false
  enable_http_endpoint            = false
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "13.8"
  port                            = 5432
  preferred_backup_window         = "02:00-03:00"
  preferred_maintenance_window    = "sun:05:00-sun:06:00"
  manage_master_user_password     = true
  skip_final_snapshot             = true
  storage_encrypted               = true

  serverlessv2_scaling_configuration {
    # Aurora Serverless automatically scales the cluster based on the number of connections
    # and CPU utilization, up to the maximum capacity. 1 ACU = 2 GiB of memory and corresponding CPU.
    # See https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html#aurora-serverless-v2.how-it-works.capacity
    max_capacity = var.airflow_db_acu_max_capacity
    min_capacity = var.airflow_db_acu_min_capacity
  }
}

resource "aws_rds_cluster_instance" "airflow_db_instance" {
  identifier          = "airflow-db-instance-${local.deployment_id}"
  cluster_identifier  = aws_rds_cluster.airflow_db.id
  engine              = aws_rds_cluster.airflow_db.engine
  engine_version      = aws_rds_cluster.airflow_db.engine_version
  instance_class      = "db.serverless"
  promotion_tier      = 1
}
