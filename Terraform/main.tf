
resource "aws_sns_topic" "hensen_test" {
    name = "hensen_test_topic"
}

resource "aws_sqs_queue" "hensen_test_queue" {
    name = "hensen_test_queue"
    redrive_policy  = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.hensen_test_dl_queue.arn}\",\"maxReceiveCount\":5}"
    visibility_timeout_seconds = 300

    tags = {
        Environment = "test"
    }
}


resource "aws_sqs_queue" "hensen_test_dl_queue" {
    name = "hensen_testdl_queue"
}

resource "aws_sqs_queue_policy" "hensen_test_queue_policy" {
    queue_url = "${aws_sqs_queue.hensen_test_queue.id}"

    policy = "${file("/Users/amargajula/Lambda/Test_lambda/test_queue_policy.json")}"

}

resource "aws_sns_topic_subscription" "hensen_test_sqs_target" {
    topic_arn = "${aws_sns_topic.hensen_test.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.hensen_test_queue.arn}"
}
resource "aws_dynamodb_table" "hensentable" {
  name             = "hensenDB"
  hash_key         = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
 

  attribute {
  name = "id"
  type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
    name = "LambdaRole" 
    assume_role_policy = "${file("/Users/amargajula/Lambda/Test_lambda/lambda_iam_role.json")}"

}

resource "aws_iam_role_policy" "lambda_role_logs_policy" {
    name = "LambdaRolePolicy"
    role = "${aws_iam_role.lambda_role.id}"
    policy = "${file("/Users/amargajula/Lambda/Test_lambda/lambda_iam_role_policy.json")}"

}

resource "aws_iam_role_policy" "lambda_role_sqs_policy" {
    name = "AllowSQSPermissions"
    role = "${aws_iam_role.lambda_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
data "archive_file" "test_zip" {
  type        = "zip"
  source_file = "new.py"
  output_path = "/Users/amargajula/Lambda/Test_lambda/index.zip"
}

resource "aws_lambda_function" "hensen_test_lambda" {
    filename         = "new.zip"
    function_name    = "assessment_example"
    role             = "${aws_iam_role.lambda_role.arn}"
    handler          = "example.handler"
    runtime          = "python3.9"

    environment {
        variables = {
            foo = "bar"
        }
    }
}

resource "aws_lambda_event_source_mapping" "hensen_test_lambda_event_source" {
    event_source_arn = "${aws_sqs_queue.hensen_test_queue.arn}"
    enabled          = true
    function_name    = "${aws_lambda_function.hensen_test_lambda.arn}"
    batch_size       = 1
  
}

resource "aws_iam_role" "lambda_assume_role" {
  name               = "lambda-dynamodb-role"
  assume_role_policy = "${file("/Users/amargajula/Lambda/Test_lambda/lambda_assume_role.json")}"
}

resource "aws_iam_role_policy" "dynamodb_read_log_policy" {
  name   = "lambda-dynamodb-log-policy"
  role   = aws_iam_role.lambda_assume_role.id
  policy = "${file("/Users/amargajula/Lambda/Test_lambda/IAM_role_Lambda_dydb.json")}"

}
