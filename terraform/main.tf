data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Red: cliente de pruebas en subred publica, BD en subredes privadas.
resource "aws_vpc" "lab" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "medibook-lab-vpc" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "medibook-lab-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.42.10.0/24"
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "medibook-public-client" }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.42.${20 + count.index}.0/24"
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "medibook-db-private-${count.index + 1}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = { Name = "medibook-public-route" }
}

resource "aws_route_table_association" "client" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "client" {
  name_prefix = "medibook-client-"
  vpc_id      = aws_vpc.lab.id
  description = "Cliente: sin accesos entrantes desde internet"
  egress {
    description = "Salida requerida para SSM y conexiones SQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name_prefix = "medibook-db-"
  vpc_id      = aws_vpc.lab.id
  description = "MySQL solo desde EC2 de pruebas"
  ingress {
    description     = "MySQL solo desde cliente EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.client.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "database" {
  name       = "medibook-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "medibook-db-subnets" }
}

# A: Aurora MySQL con dos instancias distribuidas por zonas.
resource "aws_rds_cluster" "aurora" {
  cluster_identifier          = "medibook-aurora-lab"
  engine                      = "aurora-mysql"
  database_name               = "medibook"
  master_username             = "adminmedibook"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.database.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  storage_encrypted           = true
  backup_retention_period     = 1
  skip_final_snapshot         = true
  deletion_protection         = false
  apply_immediately           = true
  tags                        = { Name = "medibook-aurora" }
}

resource "aws_rds_cluster_instance" "aurora" {
  count                = 2
  identifier           = "medibook-aurora-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  db_subnet_group_name = aws_db_subnet_group.database.name
  availability_zone    = local.azs[count.index]
  publicly_accessible  = false
  apply_immediately    = true
  tags                 = { Name = "medibook-aurora-${count.index + 1}" }
}

# B: RDS MySQL con standby Multi-AZ (no atiende lecturas).
resource "aws_db_instance" "mysql" {
  identifier                  = "medibook-rds-mysql-lab"
  engine                      = "mysql"
  instance_class              = var.rds_instance_class
  allocated_storage           = 20
  storage_type                = "gp3"
  db_name                     = "medibook"
  username                    = "adminmedibook"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.database.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  multi_az                    = true
  publicly_accessible         = false
  storage_encrypted           = true
  backup_retention_period     = 1
  skip_final_snapshot         = true
  deletion_protection         = false
  apply_immediately           = true
  tags                        = { Name = "medibook-rds-mysql" }
}

# Cliente SQL sin SSH: acceso mediante Systems Manager Session Manager.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "client" {
  name = "medibook-lab-ssm-client-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "client" {
  name = "medibook-lab-ssm-client-profile"
  role = aws_iam_role.client.name
}

resource "aws_instance" "client" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.client.id]
  iam_instance_profile        = aws_iam_instance_profile.client.name
  associate_public_ip_address = true
  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }
  user_data  = <<-EOF_USER_DATA
    #!/bin/bash
    dnf install -y mariadb105 python3 python3-pip
  EOF_USER_DATA
  tags       = { Name = "medibook-sql-client-ssm" }
  depends_on = [aws_iam_role_policy_attachment.ssm]
}
