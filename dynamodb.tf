
//main.tf

locals {
  table_name     = "YOUR_table_Name"
  gsi_uuid_index = "uuid_index"
}

resource "aws_dynamodb_table" "mail_checker_messages" {
  lifecycle {
    ignore_changes = [replica, global_secondary_index, read_capacity, write_capacity]
  }

  name = local.table_name
  read_capacity  = var.min_read_capacity
  write_capacity = var.min_write_capacity

  
  attribute {
    name = "address"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "uuid"
    type = "S"
  }

  global_secondary_index {
    hash_key           = "uuid"
    name               = local.gsi_uuid_index
    non_key_attributes = []
    projection_type    = "ALL"
    range_key          = "date"
    read_capacity      = var.min_read_capacity
    write_capacity     = var.min_write_capacity
  }

  hash_key  = "address"
  range_key = "date"

  server_side_encryption {
    enabled = true
  }

  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }

  tags = module.tags.tag_map
}

# Define Auto-Scaling Targets for Read and Write Capacity
resource "aws_appautoscaling_target" "dynamodb_read_target" {
  min_capacity       = var.min_read_capacity
  max_capacity       = var.max_read_capacity
  resource_id        = "table/${local.table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "dynamodb_write_target" {
  min_capacity       = var.min_write_capacity
  max_capacity       = var.max_write_capacity
  resource_id        = "table/${local.table_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_read_policy" {
  name               = "dynamodb-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "table/${local.table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  target_tracking_scaling_policy_configuration {
    target_value = var.target_read_value
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "dynamodb_write_policy" {
  name               = "dynamodb-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "table/${local.table_name}"  
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  target_tracking_scaling_policy_configuration {
    target_value = var.target_write_value
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

resource "aws_appautoscaling_target" "gsi_read_target" {
  min_capacity       = var.min_read_capacity
  max_capacity       = var.max_read_capacity
  resource_id        = "table/${local.table_name}/index/${local.gsi_uuid_index}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "gsi_read_policy" {
  name               = "gsi-read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "table/${local.table_name}/index/${local.gsi_uuid_index}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value =var.target_read_value
  }
}

resource "aws_appautoscaling_target" "gsi_write_target" {
  min_capacity       =  var.min_write_capacity
  max_capacity       =  var.max_write_capacity
  resource_id        = "table/${local.table_name}/index/${local.gsi_uuid_index}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "gsi_write_policy" {
  name               = "gsi-write-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "table/${local.table_name}/index/${local.gsi_uuid_index}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.target_write_value
  }
}
//tf.variables
  
variable "max_read_capacity" {
  description = "Maximum read capacity for DynamoDB scaling"
  type        = number
}

variable "min_read_capacity" {
  description = "Minimum read capacity for DynamoDB scaling"
  type        = number
}

variable "target_read_value" {
  description = "Target value for DynamoDB read scaling policy"
  type        = number
}

variable "max_write_capacity" {
  description = "Maximum write capacity for DynamoDB scaling"
  type        = number
}

variable "min_write_capacity" {
  description = "Minimum write capacity for DynamoDB scaling"
  type        = number
}

variable "target_write_value" {
  description = "Target value for DynamoDB write scaling policy"
  type        = number
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale-in activity"
  type        = number
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale-out activity"
  type        = number
}