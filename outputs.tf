output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.k8s_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.k8s_instance.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.k8s_instance.public_ip}"
}