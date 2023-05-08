# step-2 cluster is like a VPC, inside the cluster we have to create instances
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.env}-aurora-cluster-demo"
  engine                  = var.engine
  engine_version          = var.engine_version
  database_name           = var.database_name
  master_username         = data.aws_ssm_parameter.user.value
  master_password         = data.aws_ssm_parameter.user.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  db_subnet_group_name = aws_db_subnet_group.main.name
  # availability_zones      = ["us-west-2a"] not required as we are giving >> db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [aws_security_group.main.id]
  tags = merge(var.tags,
    { Name = "${var.env}-rds" })
}

# secrets = [ in roboshop-infra/aws-parameters/env-dev/main.tfvars
# {name = "test1" , value = "hello universe" , type = "string"  ,
# { name = "dev.rds.user", value = "admin1" , type = "SecureString" } ,    # creating docdb parameter for USER
# { name = "dev.rds.pass", value = "RoboShop1" , type = "SecureString" } , # creating docdb parameter for PASSWORD
# ]

# step-1
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags,
    { Name = "${var.env}-rds-subnet-group" })
}

step-3
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.no_of_instances
  identifier         = "${var.env}-aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}

# RDS_endpoint is already available in >> resource _ aws_rds_cluster.main,
# we are refering to that value
resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "${var.env}.rds.endpoint"
  type  = "String"
  value = aws_rds_cluster.main.endpoint
}
#--------------------------------------------------------------------------

resource "aws_security_group" "main" {
  name        = "rds-${var.env}"
  description = "rds-${var.env}"
  vpc_id      = var.vpc_id    # vpc_id is coming from tf-module-vpc >> output_block

  # We need to open the Application port & we also need too tell to whom that port is opened
  # (i.e who is allowed to use that application port)
  # I.e shat port to open & to whom to open
  # Example for CTALOGUE we will open port 8080 ONLY WITHIN the APP_SUBNET
  # So that the following components (i.e to USER / CART / SHIPPING / PAYMENT) can use CATALOGUE.
  # And frontend also is necessarily need not be accessing the catalogue, i.e not to FRONTEND, because frontend belongs to web_subnet
  ingress {
    description      = "APP"
    from_port        = 3306   # rds port number
    to_port          = 3306   # rds port number
    protocol         = "tcp"
    cidr_blocks      = var.allow_subnets  # we want cidr number not subnet_id
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(var.tags,
    { Name = "rds-${var.env}" })
}
