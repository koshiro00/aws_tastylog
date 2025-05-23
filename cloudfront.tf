# ----------------------
# CloudFront Cache Distribution
# ----------------------
resource "aws_cloudfront_distribution" "cf" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "cache distribution"
  price_class     = "PriceClass_All" # すべてのリージョンを使用する場合は、PriceClass_Allを指定

  origin {
    domain_name = aws_route53_record.route53_record.fqdn # Route53のドメイン名を指定
    origin_id   = aws_alb.alb.name

    custom_origin_config {
      origin_protocol_policy = "match-viewer"                  # CloudFrontとALB間の通信はHTTPSを使用するため、match-viewerを指定
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"] # デフォルト値をそのまま記述
      http_port              = 80
      https_port             = 443
    }
  }

  origin {
    domain_name = aws_s3_bucket.s3_static_bucket.bucket_regional_domain_name # S3のドメイン名
    origin_id   = aws_s3_bucket.s3_static_bucket.id

    s3_origin_config {
      # どのidentifyでS3にアクセスするかを指定
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.cloudfront_access_identity_path
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/public/*" # キャッシュするパスを指定
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3_static_bucket.id

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none" # Cookieはキャッシュしない
      }
    }

    viewer_protocol_policy = "redirect-to-https" # HTTPからHTTPSにリダイレクト
    min_ttl                = 0
    default_ttl            = 86400    # 1日
    max_ttl                = 31536000 # 1年
    compress               = true     # 圧縮を有効
  }

  # デフォルトのキャッシュ動作を指定
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    target_origin_id       = aws_alb.alb.name
    viewer_protocol_policy = "redirect-to-https" # HTTPからHTTPSにリダイレクト
    # ELBは動的なためキャッシュしない
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # 制限なし
    }
  }

  aliases = ["dev.${var.domain}"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn # Virginiaリージョンで発行したSSL証明書
    minimum_protocol_version = "TLSv1.2_2019"                        # 推奨値
    ssl_support_method       = "sni-only"                            # 推奨値
  }
}

resource "aws_cloudfront_origin_access_identity" "cf_s3_origin_access_identity" {
  comment = "S3 static bucket access identity"
}

resource "aws_route53_record" "route53_cloudfront" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "dev.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}