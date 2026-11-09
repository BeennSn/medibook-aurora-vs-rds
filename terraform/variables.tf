variable "aws_region" {
  description = "Region de pruebas de AWS"
  type        = string
  default     = "us-east-2"
}

variable "aurora_instance_class" {
  description = "Clase por instancia Aurora (2 instancias)"
  type        = string
  default     = "db.t4g.medium"
}

variable "rds_instance_class" {
  description = "Clase para RDS MySQL Multi-AZ"
  type        = string
  default     = "db.t4g.micro"
}

variable "ec2_instance_type" {
  description = "Instancia para pruebas SQL, administrada con SSM"
  type        = string
  default     = "t3.micro"
}
