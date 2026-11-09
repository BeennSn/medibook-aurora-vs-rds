output "aurora_writer_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}
output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}
output "rds_mysql_endpoint" {
  value = aws_db_instance.mysql.address
}
output "aurora_secret_arn" {
  value = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}
output "rds_secret_arn" {
  value = aws_db_instance.mysql.master_user_secret[0].secret_arn
}
output "ec2_client_instance_id" {
  value = aws_instance.client.id
}
