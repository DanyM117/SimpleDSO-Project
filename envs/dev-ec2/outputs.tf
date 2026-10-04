output "instance_id" {
  value = aws_instance.monolith.id
}

output "public_ip" {
  value = aws_instance.monolith.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.agent_repo.repository_url
}