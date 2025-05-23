resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false # 大文字を含めない
  lower   = true  # 小文字を含める
  special = false # 特殊文字を含めない  
}

# ----------------------
# S3 Static Bucket（画像などCloudFrontから配信させるもの）
# ----------------------
resource "aws_s3_bucket" "s3_static_bucket" {
  bucket = "${var.project}-${var.environment}-static-bucket-${random_string.s3_unique_key.result}"
}

resource "aws_s3_bucket_versioning" "s3_static_bucket_versioning" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3バケットのパブリックアクセス制御設定
resource "aws_s3_bucket_public_access_block" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id

  # 完全にパブリックアクセスを禁止
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3_static_bucket_policy" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  policy = data.aws_iam_policy_document.s3_static_bucket.json
  depends_on = [
    aws_s3_bucket_public_access_block.s3_static_bucket,
    aws_s3_bucket_versioning.s3_static_bucket_versioning
  ]
}

data "aws_iam_policy_document" "s3_static_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_static_bucket.arn}/*"]
    # 全ての人を許可
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.iam_arn]
    }
  }
}

# ----------------------
# S3 deploy bucket
# ----------------------
resource "aws_s3_bucket" "s3_deploy_bucket" {
  bucket = "${var.project}-${var.environment}-deploy-bucket-${random_string.s3_unique_key.result}"
}

resource "aws_s3_bucket_versioning" "s3_deploy_bucket_versioning" {
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3バケットのパブリックアクセス制御設定
resource "aws_s3_bucket_public_access_block" "s3_deploy_bucket" {
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  # 完全にパブリックアクセスを禁止
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3_deploy_bucket_policy" {
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  policy = data.aws_iam_policy_document.s3_deploy_bucket.json
  depends_on = [
    aws_s3_bucket_public_access_block.s3_deploy_bucket,
    aws_s3_bucket_versioning.s3_deploy_bucket_versioning
  ]
}

data "aws_iam_policy_document" "s3_deploy_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_deploy_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.app_iam_role.arn]
    }
  }
}