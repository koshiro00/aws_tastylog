# ----------------------
# Certificate（SSL/TLS証明書をACMで管理）
# ----------------------
# for tokyo region
resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true # 証明書の更新時、古い証明書を削除する前に新しい証明書を作成する
  }

  depends_on = [
    aws_route53_zone.route53_zone, # Route53を作成後に証明書を作成する
  ]
}

# 確認用のDNSレコードを作成
resource "aws_route53_record" "route53_acm_dns_resolve" {
  # ネームサーバーが複数あるため複数レコードを作成
  for_each = {
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true # Route53のレコードを上書きするかどうか
  zone_id         = aws_route53_zone.route53_zone.id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 600 # TTL（Time to Live）を600秒に設定
}

# 検証が完了するまで待機（証明書がまだ発行中なのに次の処理（ELBなど）が始まってエラーになることを防ぐ）
resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn = aws_acm_certificate.tokyo_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn
  ]
}

