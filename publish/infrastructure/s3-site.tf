resource "aws_s3_bucket" "camdenwander" {
  bucket = var.domain_name

  tags = {
    Domain  = var.domain_name
    Purpose = "static-site-content"
  }
}

resource "aws_s3_bucket_versioning" "camdenwander" {
  bucket = aws_s3_bucket.camdenwander.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "camdenwander" {
  bucket = aws_s3_bucket.camdenwander.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "camdenwander" {
  bucket = aws_s3_bucket.camdenwander.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "camdenwander" {
  bucket = aws_s3_bucket.camdenwander.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.camdenwander.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.camdenwander.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.camdenwander]
}
