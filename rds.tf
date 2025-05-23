# ----------------------
# RDS parameter group
# ----------------------
resource "aws_db_parameter_group" "mysql_standalone_parametergroup" {
  name   = "${var.project}-${var.environment}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# ----------------------
# RDS option group
# ----------------------
resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}

# ----------------------
# RDS subnet group
# ----------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetgroup" {
  name = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
  subnet_ids = [
    aws_subnet.private-subnet-1a.id,
    aws_subnet.private-subnet-1c.id,
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
    Project = var.project
    Env     = var.environment
  }
}

# ----------------------
# RDS instance
# ----------------------
resource "random_string" "db_password" {
  length  = 16
  special = false # 特殊文字を含めない
}

resource "aws_db_instance" "mysql_standalone" {
  engine         = "mysql"
  engine_version = "8.0.41" # MySQLのバージョンを指定

  identifier = "${var.project}-${var.environment}-mysql-standalone"

  username = "admin"
  password = random_string.db_password.result

  instance_class = "db.t3.micro"

  allocated_storage     = 20    # デフォルトは 20GB
  max_allocated_storage = 50    # 最大ストレージサイズ
  storage_type          = "gp2" # 汎用 SSD
  storage_encrypted     = false # 暗号化しない

  multi_az               = false
  availability_zone      = "ap-northeast-1a" # AZを指定
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetgroup.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false # パブリックアクセスを無効にする
  port                   = 3306  # MySQLのデフォルトポート

  name                 = "tastylog"
  parameter_group_name = aws_db_parameter_group.mysql_standalone_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  backup_window              = "04:00-05:00"         # バックアップウィンドウ（バックアップの時間帯）
  backup_retention_period    = 7                     # バックアップ保持期間（7日間）
  maintenance_window         = "Mon:05:00-Mon:08:00" # メンテナンスウィンドウ（メンテナンスの時間帯）※メンテナンスより早い時間帯でバックアップしておくことが大事
  auto_minor_version_upgrade = false                 # 自動マイナーアップグレードを無効にする

  deletion_protection = false  # 削除保護を有効にする
  skip_final_snapshot = true # 最終スナップショットのスキップ

  apply_immediately = true # 変更を即時適用する

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone"
    Project = var.project
    Env     = var.environment
  }
}
