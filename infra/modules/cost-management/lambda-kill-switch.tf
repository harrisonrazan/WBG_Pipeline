# Lambda function for cost control kill switch
resource "aws_lambda_function" "cost_kill_switch" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-cost-kill-switch"
  role            = aws_iam_role.lambda_kill_switch_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ORGANIZATION_ID = var.organization_id
      SNS_TOPIC_ARN  = aws_sns_topic.cost_alerts.arn
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cost-kill-switch"
    Purpose = "cost-control-automation"
  })
}

# IAM role for Lambda kill switch
resource "aws_iam_role" "lambda_kill_switch_role" {
  name = "${var.project_name}-lambda-kill-switch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-lambda-kill-switch-role"
    Purpose = "cost-control-automation"
  })
}

# IAM policy for Lambda kill switch
resource "aws_iam_policy" "lambda_kill_switch_policy" {
  name = "${var.project_name}-lambda-kill-switch-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "rds:DescribeDBInstances",
          "rds:StopDBInstance",
          "ecs:ListServices",
          "ecs:UpdateService",
          "ecs:StopTask",
          "lambda:ListFunctions",
          "lambda:UpdateFunctionConfiguration",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "organizations:AttachPolicy",
          "organizations:DetachPolicy",
          "organizations:ListAccounts",
          "organizations:ListPoliciesForTarget"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-lambda-kill-switch-policy"
    Purpose = "cost-control-automation"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kill_switch_policy_attachment" {
  role       = aws_iam_role.lambda_kill_switch_role.name
  policy_arn = aws_iam_policy.lambda_kill_switch_policy.arn
}

# SNS topic for cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cost-alerts"
    Purpose = "cost-monitoring"
  })
}

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_subscription" "cost_alerts_lambda" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cost_kill_switch.arn
}

# CloudWatch alarm for budget exceeding
resource "aws_cloudwatch_metric_alarm" "budget_exceeded" {
  alarm_name          = "${var.project_name}-budget-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = var.monthly_budget_limit * 0.8
  alarm_description   = "This metric monitors estimated charges"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-budget-exceeded-alarm"
    Purpose = "cost-monitoring"
  })
}

# Lambda permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_kill_switch.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cost_alerts.arn
}

# Create the Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "cost_kill_switch.zip"
  source {
    content = <<EOF
import boto3
import json
import os

def lambda_handler(event, context):
    """
    Kill switch function that stops expensive resources when budget is exceeded
    """
    print(f"Cost kill switch triggered: {json.dumps(event)}")
    
    # Initialize AWS clients
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')
    ecs = boto3.client('ecs')
    autoscaling = boto3.client('autoscaling')
    organizations = boto3.client('organizations')
    sns = boto3.client('sns')
    
    actions_taken = []
    
    try:
        # 1. Stop all EC2 instances
        instances = ec2.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        
        instance_ids = []
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            ec2.stop_instances(InstanceIds=instance_ids)
            actions_taken.append(f"Stopped {len(instance_ids)} EC2 instances")
        
        # 2. Stop RDS instances
        rds_instances = rds.describe_db_instances()
        for db_instance in rds_instances['DBInstances']:
            if db_instance['DBInstanceStatus'] == 'available':
                rds.stop_db_instance(DBInstanceIdentifier=db_instance['DBInstanceIdentifier'])
                actions_taken.append(f"Stopped RDS instance: {db_instance['DBInstanceIdentifier']}")
        
        # 3. Scale down Auto Scaling Groups
        asg_response = autoscaling.describe_auto_scaling_groups()
        for asg in asg_response['AutoScalingGroups']:
            if asg['DesiredCapacity'] > 0:
                autoscaling.update_auto_scaling_group(
                    AutoScalingGroupName=asg['AutoScalingGroupName'],
                    DesiredCapacity=0
                )
                actions_taken.append(f"Scaled down ASG: {asg['AutoScalingGroupName']}")
        
        # 4. Send notification
        message = f"🚨 COST KILL SWITCH ACTIVATED 🚨\n\nActions taken:\n" + "\n".join(actions_taken)
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Message=message,
            Subject="AWS Cost Kill Switch Activated"
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Kill switch executed successfully',
                'actions_taken': actions_taken
            })
        }
        
    except Exception as e:
        error_message = f"Error in kill switch: {str(e)}"
        print(error_message)
        
        # Send error notification
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Message=f"❌ Cost kill switch failed: {error_message}",
            Subject="AWS Cost Kill Switch Error"
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_message})
        }
EOF
    filename = "index.py"
  }
} 