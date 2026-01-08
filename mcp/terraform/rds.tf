# terraform/rds.tf

# Security group for the RDS instance
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Allow traffic to the RDS instance"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from the application security group
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# Subnet group for the RDS instance
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS instance
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "18.1"
  instance_class       = "db.t3.micro"
  db_name              = "mcpdatabase"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot  = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
