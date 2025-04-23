# ECR Repository for Embedding Worker
resource "aws_ecr_repository" "embedding_worker" {
  name                 = "${var.project}-embedding-worker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project}-embedding-worker"
    Environment = var.environment
  }
}

# ECR Lifecycle Policy to clean up untagged images
resource "aws_ecr_lifecycle_policy" "embedding_worker_lifecycle" {
  repository = aws_ecr_repository.embedding_worker.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 5
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images older than 1 day",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Add ECR Pull permissions to EC2 instance role
resource "aws_iam_policy" "embedding_worker_ecr_policy" {
  name        = "${var.project}-embedding-worker-ecr-policy"
  description = "Allows embedding worker to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach ECR policy to EC2 role
resource "aws_iam_role_policy_attachment" "embedding_worker_ecr" {
  role       = aws_iam_role.embedding_worker_role.name
  policy_arn = aws_iam_policy.embedding_worker_ecr_policy.arn
}

# Output the ECR repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.embedding_worker.repository_url
}
