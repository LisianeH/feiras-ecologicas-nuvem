output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = aws_instance.frontend.id
}

output "frontend_public_ip" {
  description = "Public IP of the frontend EC2 instance"
  value       = aws_instance.frontend.public_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.contact_queue.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.notifications.arn
}
