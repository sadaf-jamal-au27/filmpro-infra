output "myami" {
  description = "This is my ami id : "
  value       = data.aws_ami.my_ami.id
}

output "publicip" {
  description = "The public ip of my EC2 instance is : "
  value       = aws_instance.my_server.public_ip
}

output "connect_command" {
  description = "Command to connect to the EC2 instance using AWS Systems Manager Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.my_server.id}"
}

output "security_group_id" {
  description = "Security Group ID for post-deployment verification"
  value       = aws_security_group.my_server_sg.id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.my_server.id
}

output "jenkins_url" {
  description = "Jenkins URL for accessing the application"
  value       = "http://${aws_instance.my_server.public_ip}:8080"
}
