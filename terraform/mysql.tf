
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

/*
resource "aws_db_instance" "postgres" {
engine               = "postgres"
  engine_version       = "11.10"
  family               = "postgres11" # DB parameter group
  major_engine_version = "11"         # DB option group
  instance_class       = "db.t3.large"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  name     = "completePostgresql"
  username = "complete_postgresql"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = 5432
}

resource "aws_db_instance" "education" {
    identifier             = "education"
    instance_class         = "db.t3.micro"
    allocated_storage      = 5
    engine                 = "postgres"
    engine_version         = "13.1"
    username               = "edu"
    password               = var.db_password
    db_subnet_group_name   = aws_db_subnet_group.education.name
    vpc_security_group_ids = [aws_security_group.rds.id]
    parameter_group_name   = aws_db_parameter_group.education.name
    publicly_accessible    = true
    skip_final_snapshot    = true
    }
*/