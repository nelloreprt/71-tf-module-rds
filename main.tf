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