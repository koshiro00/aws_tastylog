# ----------------------
# Security Group
# ----------------------

# web server security group
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "web front role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-web-sg"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_security_group_rule" "web_in_http" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_in_https" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

# 3000ポートへの接続を許可（webサーバーからアプリケーションサーバーへの接続）
resource "aws_security_group_rule" "web_out_tcp3000" {
  security_group_id        = aws_security_group.web_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = aws_security_group.app_sg.id
}

# app server security group
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "application server role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-app-sg"
    Project = var.project
    Env     = var.environment
  }
}

# 3000ポートを解放（webサーバー ▶︎ アプリケーションサーバー）
resource "aws_security_group_rule" "app_in_tcp_3000" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = aws_security_group.web_sg.id # webサーバーからの接続を許可
}

# 80ポートへの接続を許可（アプリケーションサーバー▶︎S3）
resource "aws_security_group_rule" "app_sg_out_http" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_ids   = [data.aws_prefix_list.s3_pl.id] # S3への接続のみを許可
}

# 443ポートへの接続を許可（アプリケーションサーバー▶︎S3）
resource "aws_security_group_rule" "app_sg_out_https" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_prefix_list.s3_pl.id] # S3への接続のみを許可
}

# 3306ポートへの接続を許可（アプリケーションサーバー▶︎データベースサーバー）
resource "aws_security_group_rule" "app_sg_out_tcp_3306" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.db_sg.id # DBサーバーへの接続のみを許可
}


# operation manage security group
resource "aws_security_group" "opnmg_sg" {
  name        = "${var.project}-${var.environment}-opnmg-sg"
  description = "operation and management role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-opnmg-sg"
    Project = var.project
    Env     = var.environment
  }
}

# 22ポートを開放（ssh接続でアプリをデプロイする際に使用）
resource "aws_security_group_rule" "opnmg_sg_in_ssh" {
  security_group_id = aws_security_group.opnmg_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

# 3000ポートを解放（全てのサーバー▶︎オペレーション管理サーバー）
resource "aws_security_group_rule" "opnmg_sg_in_tcp3000" {
  security_group_id = aws_security_group.opnmg_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
}

# 80ポートへの接続を許可
resource "aws_security_group_rule" "opnmg_sg_out_http" {
  security_group_id = aws_security_group.opnmg_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

# 443ポートへの接続を許可
resource "aws_security_group_rule" "opnmg_sg_out_https" {
  security_group_id = aws_security_group.opnmg_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

# database security group
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "database role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-db-sg"
    Project = var.project
    Env     = var.environment
  }
}

# 3306ポートを解放（アプリケーションサーバー▶︎データベースサーバー）
resource "aws_security_group_rule" "db_in_tcp3306" {
  security_group_id        = aws_security_group.db_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.app_sg.id
}