# resource "aws_api_gateway_rest_api" "example" {
#   body = jsonencode({
#     openapi = "3.0.1"
#     info = {
#       title   = "rest-api-gw-1"
#       version = "1.0"
#     }
#     paths = {
#       "/" = {
#         get = {
#           x-amazon-apigateway-integration = {
#             httpMethod           = "GET"
#             payloadFormatVersion = "1.0"
#             type                 = "HTTP_PROXY"
#             uri                  = "http://www.google.com"
#           }
#         }
#       }
#     }
#   })

#   name = "existing_api" 
 
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

data "aws_api_gateway_rest_api" "my_rest_api" {
  name = "existing_api"
}

resource "aws_api_gateway_rest_api_policy" "example" {
  rest_api_id = data.aws_api_gateway_rest_api.my_rest_api.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "execute-api:*",
                "lambda:InvokeFunction"
            ],
            "Resource": "${data.aws_api_gateway_rest_api.my_rest_api.execution_arn}/*/GET/user"
        }
    ]
}
EOF
}

# "arn:aws:execute-api:ap-south-1:723399834836:ykla5jxj0f/*/GET/oktatest"


resource "aws_api_gateway_resource" "resource-gw" {
  parent_id   = data.aws_api_gateway_rest_api.my_rest_api.root_resource_id
  path_part   = "user"
  rest_api_id = data.aws_api_gateway_rest_api.my_rest_api.id
}

resource "aws_api_gateway_authorizer" "example" {
  name                   = "api-auth-1"
  rest_api_id            = data.aws_api_gateway_rest_api.my_rest_api.id
  authorizer_uri         = aws_lambda_function.test_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.iam_for_lambda.arn
}

resource "aws_api_gateway_method" "example" {
  authorization = "CUSTOM"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.resource-gw.id
  rest_api_id   = data.aws_api_gateway_rest_api.my_rest_api.id
  authorizer_id = aws_api_gateway_authorizer.example.id
}

resource "aws_api_gateway_integration" "example" {
  integration_http_method = "GET"
  resource_id             = aws_api_gateway_resource.resource-gw.id
  rest_api_id             = "${data.aws_api_gateway_rest_api.my_rest_api.id}"
  type                    = "HTTP_PROXY"
  http_method             = aws_api_gateway_method.example.http_method
  uri                     = "https://google.com"
}


resource "aws_api_gateway_deployment" "example" {
  rest_api_id = data.aws_api_gateway_rest_api.my_rest_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource-gw.id,
      aws_api_gateway_method.example.id,
      aws_api_gateway_integration.example.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = data.aws_api_gateway_rest_api.my_rest_api.id
  stage_name    = "api-stage-1"
}


resource "aws_api_gateway_usage_plan" "example" {
  name         = "my-usage-plan"
  description  = "my description"
  product_code = "MYCODE"
}


resource "aws_api_gateway_api_key" "example" {
  name      = "mykey"
 
}

resource "aws_api_gateway_usage_plan_key" "example" {
  key_id            = aws_api_gateway_api_key.example.id
  key_type          = "API_KEY"
  usage_plan_id     = aws_api_gateway_usage_plan.example.id
}

output "api-id" {
  value = data.aws_api_gateway_rest_api.my_rest_api.id
}
output "api-arn" {
  value = data.aws_api_gateway_rest_api.my_rest_api.execution_arn
}
output "api-arn-noex" {
  value = data.aws_api_gateway_rest_api.my_rest_api.arn
}