////////////////////// Module //////////////////////////



output "database_username" {
  value = aws_db_instance.default.username
   sensitive = false
}

output "database_password" {
  value = aws_db_instance.default.password
   sensitive = true
}

output "database_hostname" {
  value = aws_db_instance.default.address
  sensitive = false
}

output "database_port" {
  value = aws_db_instance.default.port
  sensitive = false
}

output "database_name" {
  value = aws_db_instance.default.name
  sensitive = false
}

output "workers" {
  value = aws_instance.workers.public_dns
}

output "hcp_vault_private_address" {
  value = hcp_vault_cluster.hcp_demostack.vault_private_endpoint_url
}