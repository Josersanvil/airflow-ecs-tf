
resource "aws_iam_policy" "airflow_allow_ecs_cluster_policy" {
  name        = "airflow_allow_ecs_cluster_policy_${local.deployment_id}"
  description = "Allow Airflow DAGs to access the ECS cluster and to run tasks on it using the ECS Operator"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow access to the ECS cluster
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:StartTask",
          "ecs:RunTask",
          "ecs:StopTask",
        ],
        Effect = "Allow"
        Resource = [
          aws_ecs_cluster.airflow_cluster.arn,
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.airflow_cluster.name}/*",
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task-definition/*"
        ]
      },
      {
        # Allow access to create and delete ECS task definitions in the account
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
        ],
        Effect   = "Allow"
        Resource = "*"
      },
      {
        # Explicit Deny access to the services used by the Airflow Control Plane
        Action = [
          "ecs:*"
        ],
        Effect = "Deny"
        Resource = [
          aws_ecs_service.airflow_webserver.id,
          aws_ecs_service.airflow_control_plane["airflow-scheduler"].id,
          aws_ecs_service.airflow_control_plane["airflow-triggerer"].id,
          aws_ecs_service.airflow_control_plane["airflow-worker"].id,
        ]
      },
      {
        # Explicit Deny access to the task definitions used by the Airflow Control Plane
        Action = [
          "ecs:DeregisterTaskDefinition",
        ],
        Effect = "Deny"
        Resource = [
          aws_ecs_task_definition.airflow_webserver.arn,
          aws_ecs_task_definition.airflow_scheduler.arn,
          aws_ecs_task_definition.airflow_triggerer.arn,
          aws_ecs_task_definition.airflow_worker.arn,
        ]
      },
      {
        # Allow to stream logs from the ECS tasks
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ],
        Effect = "Allow"
        Resource = [
          aws_cloudwatch_log_group.airflow_logs.arn,
          "${aws_cloudwatch_log_group.airflow_logs.arn}:*",
          "${aws_cloudwatch_log_group.airflow_logs.arn}/*"
        ]
      },
      {
        # Allow to pass the IAM role to the ECS tasks
        Action = [
          "iam:PassRole",
          "iam:GetRole",
        ],
        Effect = "Allow"
        Resource = [
          aws_iam_role.airflow_ecs_task_role.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "airflow_ecs_execution_role" {
  name = "airflow_ecs_execution_role_${local.deployment_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "ECSTaskExecutionRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

resource "aws_iam_role" "airflow_ecs_task_role" {
  name = "airflow_ecs_task_role_${local.deployment_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "airflow_ecs_task_role_ecs_execution_role_policy" {
  role       = aws_iam_role.airflow_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "airflow_ecs_task_role_allow_ecs_cluster_policy" {
  role       = aws_iam_role.airflow_ecs_task_role.name
  policy_arn = aws_iam_policy.airflow_allow_ecs_cluster_policy.arn
}

resource "aws_iam_role_policy_attachment" "user_defined_iam_policies" {
  for_each   = toset(var.execution_iam_policies_arns)
  role       = aws_iam_role.airflow_ecs_task_role.name
  policy_arn = each.value
}

