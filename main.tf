resource "aws_lambda_function" "health" {
  function_name = "health"
  memory_size   = 128
  timeout       = 10
  //exe name
  handler          = "health"
  filename         = data.archive_file.bundle["health"].output_path
  source_code_hash = data.archive_file.bundle["health"].output_base64sha256
  role             = aws_iam_role.lambda.arn
  environment {
    variables = {
      BUCKET_NAME = "hi"
    }
  }
  //repeats 
  runtime = "go1.x"
}

//Dont forget to add this
//once this issue is passed https://github.com/hashicorp/terraform/issues/19931#
locals {
  lambdas = [
    aws_lambda_function.health
  ]

}

resource "null_resource" "lambdas_build" {
  triggers = {
    watch = join("", [
      for file in fileset("where ever your functions are", "*.go") : filebase64("../backend/cmd/functions/${each.value}")
    ])
  }
  for_each = { for file_path in fileset("where ever your functions are", "*.go") : trimsuffix(file_path, ".go") => file_path }
  provisioner "local-exec" {
    working_dir = "../backend"
    command     = "GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o out/${each.key} cmd/functions/${each.value}"
  }
}

data "archive_file" "bundle" {
  depends_on = [null_resource.lambdas_build]

  for_each    = { for file_path in fileset("where ever your functions are", "*.go") : trimsuffix(file_path, ".go") => file_path }
  type        = "zip"
  source_file = "../backend/out/${each.key}"
  output_path = "../backend/out/${each.key}.zip"
}
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example"
  description = "example"
  body = templatefile("./api.yaml",
    //gives access to file_name inside api.yml
    { for lambda in local.lambdas : lambda.handler => lambda.invoke_arn }
  )
}

