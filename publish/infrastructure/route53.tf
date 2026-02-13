resource "aws_route53_zone" "camdenwander" {
  name = var.domain_name

  tags = {
    Domain = var.domain_name
  }
}

resource "aws_route53domains_registered_domain" "camdenwander" {
  provider    = aws.root
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = aws_route53_zone.camdenwander.name_servers
    content {
      name = name_server.value
    }
  }
}

resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.camdenwander.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.camdenwander.domain_name
    zone_id                = aws_cloudfront_distribution.camdenwander.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.camdenwander.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.camdenwander.domain_name
    zone_id                = aws_cloudfront_distribution.camdenwander.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.camdenwander.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.camdenwander.domain_name
    zone_id                = aws_cloudfront_distribution.camdenwander.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.camdenwander.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.camdenwander.domain_name
    zone_id                = aws_cloudfront_distribution.camdenwander.hosted_zone_id
    evaluate_target_health = false
  }
}
