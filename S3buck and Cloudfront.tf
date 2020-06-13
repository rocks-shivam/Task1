provider "aws"{
region    = "ap-south-1"
profile   = "shivam2"
}
resource "aws_s3_bucket" "mycloud-bucket" {

        bucket = "my-task1-img-bucket12"
	acl = "public-read-write"
	tags = {
		Name = "task1-image-bucket"
	}
}
 
resource "aws_s3_bucket_object" "image-jpg" {
depends_on = [
aws_s3_bucket.mycloud-bucket,
]
bucket = "my-task1-img-bucket12"
	key = "s3image.jpg"
        source = "../task1(a)/s3image/s3image.jpg"
	etag = filemd5("../task1(a)/s3image/s3image.jpg")
	
	acl = "public-read-write"
}

locals {
	s3_origin_id = "s3-origin"
}

resource "aws_cloudfront_distribution" "my-s3-distribution" {
depends_on = [
aws_s3_bucket_object.image-jpg,
]
	enabled = true
	is_ipv6_enabled = true
	
	origin {
		domain_name = aws_s3_bucket.mycloud-bucket.bucket_regional_domain_name
		origin_id = local.s3_origin_id
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	default_cache_behavior {
		target_origin_id = local.s3_origin_id
		allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    	cached_methods  = ["HEAD", "GET", "OPTIONS"]

    	forwarded_values {
      		query_string = false
      		cookies {
        		forward = "none"
      		}
		}

		viewer_protocol_policy = "redirect-to-https"
    	min_ttl                = 0
    	default_ttl            = 120
    	max_ttl                = 86400
	}

	viewer_certificate {
    	cloudfront_default_certificate = true
  	}
}
output "myclf"{
value     = aws_cloudfront_distribution.my-s3-distribution.domain_name
}
