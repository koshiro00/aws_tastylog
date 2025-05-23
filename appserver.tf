# ----------------------
# key pair
# ----------------------
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/tastylog-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

# ----------------------
# Parameter Store
# ----------------------
resource "aws_ssm_parameter" "host" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  type  = "String"
  value = aws_db_instance.mysql_standalone.address
}

resource "aws_ssm_parameter" "port" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}

resource "aws_ssm_parameter" "database" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
  type  = "String"
  value = aws_db_instance.mysql_standalone.name
}

resource "aws_ssm_parameter" "username" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  type  = "SecureString" # SecureStringにすることで、AWS Systems ManagerのParameter Storeで暗号化される
  value = aws_db_instance.mysql_standalone.username
}

resource "aws_ssm_parameter" "password" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.password
}

# ----------------------
# EC2 Instance ← Launch Templateに置き換え
# ----------------------
# resource "aws_instance" "app_server" {
#   ami                         = data.aws_ami.app.id
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public-subnet-1a.id
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name

#   vpc_security_group_ids = [
#     aws_security_group.app_sg.id,
#     aws_security_group.opnmg_sg.id,
#   ]
#   key_name = aws_key_pair.keypair.key_name

#   tags = {
#     Name    = "${var.project}-${var.environment}-app-ec2"
#     Project = var.project
#     Env     = var.environment
#     Type    = "app"
#   }
# }

# ----------------------
# Launch Template（起動テンプレート_Auto Scaling用）
# ----------------------

resource "aws_launch_template" "app_lt" {
  update_default_version = true
  name                   = "${var.project}-${var.environment}-app-lt"

  image_id = data.aws_ami.app.id
  key_name = aws_key_pair.keypair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-app-ec2"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.opnmg_sg.id,
    ]

    delete_on_termination = true # EC2が消えた時にネットワークも消す
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  user_data = filebase64("./src/initialize.sh") # EC2起動時に実行するスクリプト

}

# ----------------------
# Auto Scaling Group
# ----------------------
resource "aws_autoscaling_group" "app_asg" {
  name = "${var.project}-${var.environment}-app-asg"

  max_size         = 1 # 最大台数
  min_size         = 1 # 最小台数
  desired_capacity = 1 # 起動する台数

  health_check_grace_period = 300 # ヘルスチェックを待つ時間
  health_check_type         = "ELB"

  vpc_zone_identifier = [
    aws_subnet.public-subnet-1a.id,
    aws_subnet.public-subnet-1c.id,
  ]

  target_group_arns = [aws_lb_target_group.alb_target_group.arn]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt.id
        version            = "$Latest" # 最新バージョンを指定
      }
      override {
        instance_type = "t2.micro" # インスタンスタイプを指定
      }
    }
  }
}