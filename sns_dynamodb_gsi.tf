locals {
  environment = "dev"
}

resource "aws_sns_topic" "alarm_notifications" {
  name              = "${local.environment}-alarm-notifications"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "alarm_notification_email" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = "xxxx"   //add your email

resource "aws_sqs_queue" "alarm_notification_queue" {
  name                      = "${local.environment}-alarm-notification-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "sns_sqs_policy" {
  queue_url = aws_sqs_queue.alarm_notification_queue.id
  policy    = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.alarm_notification_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.alarm_notifications.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "alarm_notification_sqs_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.alarm_notification_queue.arn
}

# Primary Table Alarms

resource "aws_cloudwatch_metric_alarm" "high_read_capacity_utilization" {
  alarm_name          = "High Read Capacity Utilization - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when DynamoDB read capacity utilization exceeds 80% in ${local.environment}"
  dimensions = {
    TableName = "YOUR TABLE NAME "
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_write_capacity_utilization" {
  alarm_name          = "High Write Capacity Utilization - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when DynamoDB write capacity utilization exceeds 80% in ${local.environment}"
  dimensions = {
    TableName = "YOUR TABLE NAME"
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled_requests" {
  alarm_name          = "DynamoDB Throttled Requests - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there is at least 1 throttled request in DynamoDB for ${local.environment}"
  dimensions = {
    TableName = "YOUR TABLE NAME"
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}

# GSI Alarms

resource "aws_cloudwatch_metric_alarm" "gsi_high_read_capacity_utilization" {
  alarm_name          = "GSI High Read Capacity Utilization - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when GSI read capacity utilization exceeds 80% in ${local.environment}"
  dimensions = {
    IndexName = "YOUR SECONDARY_GLOBAL_INDEX"
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "gsi_high_write_capacity_utilization" {
  alarm_name          = "GSI High Write Capacity Utilization - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when GSI write capacity utilization exceeds 80% in ${local.environment}"
  dimensions = {
    IndexName = "YOUR SECONDARY_GLOBAL_INDEX"
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "gsi_throttled_requests" {
  alarm_name          = "GSI Throttled Requests - ${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there is at least 1 throttled request in GSI for ${local.environment}"
  dimensions = {
    IndexName = "YOUR SECONDARY_GLOBAL_INDEX"
  }
  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}
