resource "aws_cloudfront_origin_access_control" "camdenwander" {
  name                              = "${var.domain_name}-oac"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "www_redirect" {
  name    = "${replace(var.domain_name, ".", "-")}-www-redirect"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var host = request.headers.host.value;

      if (host.startsWith('www.')) {
        var newHost = host.substring(4);
        var newUrl = 'https://' + newHost + request.uri;
        if (request.querystring && Object.keys(request.querystring).length > 0) {
          var qs = Object.keys(request.querystring)
            .map(function(k) {
              var v = request.querystring[k];
              return v.multiValue
                ? v.multiValue.map(function(mv) { return k + '=' + mv.value; }).join('&')
                : k + '=' + v.value;
            })
            .join('&');
          newUrl += '?' + qs;
        }
        return {
          statusCode: 301,
          statusDescription: 'Moved Permanently',
          headers: {
            location: { value: newUrl }
          }
        };
      }

      return request;
    }
  EOF
}

resource "aws_cloudfront_response_headers_policy" "camdenwander" {
  count = var.enable_security_headers ? 1 : 0

  name = "${replace(var.domain_name, ".", "-")}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "camdenwander" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document
  price_class         = var.cloudfront_price_class
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  origin {
    domain_name              = aws_s3_bucket.camdenwander.bucket_regional_domain_name
    origin_id                = "S3-${var.domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.camdenwander.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.domain_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = var.enable_security_headers ? aws_cloudfront_response_headers_policy.camdenwander[0].id : null

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_redirect.arn
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = var.error_page_path
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = var.error_page_path
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.camdenwander.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Domain = var.domain_name
  }
}
