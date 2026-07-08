# terraform/iam.tf

# IAM role for the ECS task
resource "aws_iam_role" "task" {
  name = "${var.project_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-task-role"
  }
}

# IAM role for the ECS task execution
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-task-execution-role"
  }
}

# Attach the AmazonECSTaskExecutionRolePolicy to the task execution role
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policy for accessing secrets and S3
resource "aws_iam_policy" "task_policy" {
  name        = "${var.project_name}-task-policy"
  description = "Policy for the ECS task to access secrets and S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = [aws_secretsmanager_secret.db_credentials.arn]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = ["${aws_s3_bucket.main.arn}/*"]
      }
    ]
  })
}

# Attach the policy to the task role
resource "aws_iam_role_policy_attachment" "task_policy" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_policy.arn
}
