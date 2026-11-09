resource "aws_iam_role_policy" "client_db_secrets" {
  name = "medibook-client-secrets-access"
  role = aws_iam_role.client.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_rds_cluster.aurora.master_user_secret[0].secret_arn,
          aws_db_instance.mysql.master_user_secret[0].secret_arn
        ]
      }
    ]
  })
}
