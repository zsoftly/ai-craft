# terraform/s3.tf

# S3 bucket for storing OpenAPI specification files
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-openapi-specs"

  tags = {
    Name = "${var.project_name}-openapi-specs"
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy to allow access from the application
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# IAM policy document for S3 bucket access
data "aws_iam_policy_document" "s3_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.task.arn]
    }
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}
