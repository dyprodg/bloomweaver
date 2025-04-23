# Auto Scaling Group for Embedding Worker
resource "aws_autoscaling_group" "embedding_worker" {
  name                = "${var.project}-embedding-worker-asg"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 0
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.embedding_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-embedding-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  # Cool down periods
  default_cooldown          = 60
  health_check_grace_period = 60
  health_check_type         = "EC2"

  # Ensure proper termination when scaling in
  termination_policies = ["OldestInstance"]

  # Use instance protection to avoid terminating instances with active tasks
  protect_from_scale_in = false

  # Lifecycle hook to ensure proper cleanup on termination
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_launch_template.embedding_worker]
}

# CloudWatch Alarm for SQS Queue Depth - Scale Out (Add Instances)
resource "aws_cloudwatch_metric_alarm" "queue_depth_high" {
  alarm_name          = "${var.project}-queue-depth-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This alarm monitors SQS queue depth for scaling out"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    QueueName = aws_sqs_queue.change_queue.name
  }
}

# CloudWatch Alarm for SQS Queue Depth - Scale In (Remove Instances)
resource "aws_cloudwatch_metric_alarm" "queue_depth_low" {
  alarm_name          = "${var.project}-queue-depth-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 120
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This alarm monitors SQS queue depth for scaling in"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    QueueName = aws_sqs_queue.change_queue.name
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.embedding_worker.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.embedding_worker.name
}

# Outputs
output "asg_name" {
  value = aws_autoscaling_group.embedding_worker.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in.arn
}
