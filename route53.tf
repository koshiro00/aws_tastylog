# ----------------------
# Route 53
# ----------------------
resource "aws_route53_zone" "route53_zone" {
  name          = var.domain
  force_destroy = false # ゾーンを削除する際に、関連するレコードも削除するかどうか

  tags = {
    Name    = "${var.project}-${var.environment}-domain"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route53_record" "route53_record" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev-elb.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true # ELBのヘルスチェックを有効にするかどうか
  }
}