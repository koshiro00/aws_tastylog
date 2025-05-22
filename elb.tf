# ----------------------
# ALB (Application Load Balancer)
# ----------------------
resource "aws_alb" "alb" {
  name               = "${var.project}-${var.environment}-app-alb"
  internal           = false # インターネットからアクセス可能に設定（Trueの場合はVPC内のみ）
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets = [
    aws_subnet.public-subnet-1a.id,
    aws_subnet.public-subnet-1c.id
  ]
}

resource "aws_lb_listener" "alb_listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# HTTPS接続なのでSSL証明書を指定する必要あり
resource "aws_lb_listener" "alb_listener_https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"        # SSLポリシーを指定（固定の文字列）
  certificate_arn   = aws_acm_certificate.tokyo_cert.arn # ACMで管理しているSSL証明書を指定

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# ----------------------
# target group
# ----------------------
resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.project}-${var.environment}-app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-app-tg"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_target_group_attachment" "instance" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.app_server.id
}