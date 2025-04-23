# IAM Role for Embedding Worker EC2 instances
resource "aws_iam_role" "embedding_worker_role" {
  name = "${var.project}-embedding-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-embedding-worker-role"
    Environment = var.environment
  }
}

# IAM Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "embedding_worker_profile" {
  name = "${var.project}-embedding-worker-profile"
  role = aws_iam_role.embedding_worker_role.name
}

# Policy for accessing SQS Change Queue
resource "aws_iam_policy" "embedding_worker_sqs_policy" {
  name        = "${var.project}-embedding-worker-sqs-policy"
  description = "Allows embedding worker to read from SQS change queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.change_queue.arn]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ]
        Effect = "Allow"
        Resource = [
          aws_sqs_queue.create_queue.arn,
          aws_sqs_queue.update_queue.arn
        ]
      }
    ]
  })
}

# Policy for accessing S3 Transfer Bucket
resource "aws_iam_policy" "embedding_worker_s3_policy" {
  name        = "${var.project}-embedding-worker-s3-policy"
  description = "Allows embedding worker to read from S3 transfer bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.transfer_bucket.arn,
          "${aws_s3_bucket.transfer_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach SSM policy for management
resource "aws_iam_role_policy_attachment" "embedding_worker_ssm" {
  role       = aws_iam_role.embedding_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy for logging
resource "aws_iam_role_policy_attachment" "embedding_worker_cloudwatch" {
  role       = aws_iam_role.embedding_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SQS policy to role
resource "aws_iam_role_policy_attachment" "embedding_worker_sqs" {
  role       = aws_iam_role.embedding_worker_role.name
  policy_arn = aws_iam_policy.embedding_worker_sqs_policy.arn
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "embedding_worker_s3" {
  role       = aws_iam_role.embedding_worker_role.name
  policy_arn = aws_iam_policy.embedding_worker_s3_policy.arn
}

# EC2 Launch Template for embedding worker
resource "aws_launch_template" "embedding_worker" {
  name          = "${var.project}-embedding-worker"
  image_id      = var.ec2_ami
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.embedding_worker_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ec2_volume_size
      volume_type           = var.ec2_volume_type
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.embedding_worker_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Installing Docker"
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    
    echo "Installing AWS CLI"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    
    echo "Authenticating with ECR"
    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.embedding_worker.repository_url}
    
    echo "Pulling embedding worker image from ECR"
    EMBEDDING_WORKER_IMAGE=${aws_ecr_repository.embedding_worker.repository_url}:latest
    docker pull $EMBEDDING_WORKER_IMAGE
    
    echo "Starting embedding worker container"
    docker run -d \
      --restart=always \
      -e AWS_REGION=${var.region} \
      -e SQS_CHANGE_QUEUE_URL=${aws_sqs_queue.change_queue.url} \
      -e SQS_CREATE_QUEUE_URL=${aws_sqs_queue.create_queue.url} \
      -e SQS_UPDATE_QUEUE_URL=${aws_sqs_queue.update_queue.url} \
      -e S3_TRANSFER_BUCKET=${aws_s3_bucket.transfer_bucket.bucket} \
      $EMBEDDING_WORKER_IMAGE
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project}-embedding-worker"
      Environment = var.environment
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 required for security
  }

  tags = {
    Name        = "${var.project}-embedding-worker-launch-template"
    Environment = var.environment
  }
}

# Security Group for embedding worker
resource "aws_security_group" "embedding_worker_sg" {
  name        = "${var.project}-embedding-worker-sg"
  description = "Security group for embedding worker instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project}-embedding-worker-sg"
    Environment = var.environment
  }
}
