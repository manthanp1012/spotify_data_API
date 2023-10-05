provider "aws" {
  region                   = "us-west-1"
  shared_credentials_files = ["/path/to/your/credentials"]
}

resource "aws_iam_role" "lambda_role" {
 name   = "terraform_aws_lambda_role"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy Attachment on the role.


resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

data "aws_iam_policy_document" "iam_policy_for_lambda" {

  statement {

    actions = [

      "s3:GetObject",

      "s3:PutObject",

      "s3:ListBucket"

    ]

    resources = [

      "${aws_s3_bucket.spotifydatatos3.arn}",

      "${aws_s3_bucket.spotifydatatos3.arn}/*"

    ]

  }

}
resource "aws_s3_bucket" "spotifydatatos3" {
 bucket = "spotifydatatos3"
 acl    = "private"
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/hello.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_func" {
 filename                       = "${path.module}/python/hello.zip"
 function_name                  = "Jhooq-Lambda-Function"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "hello.lambda_handler"
 source_code_hash               = filebase64sha256("${path.module}/python/hello.zip")
 runtime                        = "python3.11"
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}


output "teraform_aws_role_output" {
 value = aws_iam_role.lambda_role.name
}

output "teraform_aws_role_arn_output" {
 value = aws_iam_role.lambda_role.arn
}

output "teraform_logging_arn_output" {
 value = aws_iam_policy.iam_policy_for_lambda.arn
}