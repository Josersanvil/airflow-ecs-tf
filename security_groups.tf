resource "aws_security_group" "airflow_web_security_group" {
  name        = "airflow_web_sg_${local.deployment_id}"
  description = "Allows access to HTTP and HTTPS within the VPC"
  vpc_id      = local.airflow_vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    description = "Allows inbound access from the Web services security group on TCP port 8080"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "8080"
    protocol    = "tcp"
    self        = "false"
    to_port     = "8080"
  }

  ingress {
    description = "Allows access to the Airflow web server using HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "443"
  }

  ingress {
    description = "Allows access to the Airflow web server using HTTP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "80"
    protocol    = "tcp"
    self        = "false"
    to_port     = "80"
  }

  ingress {
    description = "Allows all traffic coming from the VPC"
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
    cidr_blocks = [local.airflow_vpc_cidr_block]
  }

  tags = {
    Name = "airflow-web-sg-${local.deployment_id}"
  }
}

resource "aws_security_group" "airflow_redis_security_group" {
  name        = "airflow_redis_sg_${local.deployment_id}"
  description = "Allows access to Redis within the VPC"
  vpc_id      = local.airflow_vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    description = "Allows inbound access from the Web services security group on TCP port 6379"
    protocol    = "tcp"
    self        = "false"
    to_port     = "6379"
    from_port   = "6379"
    cidr_blocks = [local.airflow_vpc_cidr_block]
  }
}
