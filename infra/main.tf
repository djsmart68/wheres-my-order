terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# "Terraform, you are speaking to AWS, in London."
provider "aws" { region = "eu-west-2" }

# A fill-in-the-blank supplied when you run terraform:
# which GitHub repository is trusted to deploy.
variable "github_repo" {
  description = "GitHub repo allowed to deploy, e.g. your-username/wheres-my-order"
  type        = string
}

# 1. The crate warehouse.
resource "aws_ecr_repository" "app" {
  name         = "wheres-my-order"
  force_delete = true   # sandbox convenience: lets Part 9 demolish it even if crates remain
}

# 2. "This AWS account recognises GitHub as a passport-issuing authority."
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 3. The badge the robot pipeline will wear. The Condition is the crucial line:
#    only workflows from EXACTLY your repository may wear it.
resource "aws_iam_role" "deploy" {
  name = "wheres-my-order-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*" }
      }
    }]
  })
}

# ...and the badge opens exactly one set of doors: pushing crates to OUR warehouse.
resource "aws_iam_role_policy" "deploy_ecr" {
  role = aws_iam_role.deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "ecr:GetAuthorizationToken", Resource = "*" },
      { Effect = "Allow",
        Action = ["ecr:BatchCheckLayerAvailability","ecr:PutImage",
                  "ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload"],
        Resource = aws_ecr_repository.app.arn }
    ]
  })
}

# 4. App Runner's own badge: permission to collect crates from the warehouse.
resource "aws_iam_role" "apprunner_ecr" {
  name = "wheres-my-order-apprunner-ecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole",
                   Principal = { Service = "build.apprunner.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# 5. The running service. It watches the ":latest" crate and, because
#    auto_deployments_enabled is true, REDEPLOYS ITSELF whenever that crate
#    changes. That single line is the hinge Part 7 turns on.
resource "aws_apprunner_service" "app" {
  service_name = "wheres-my-order"
  source_configuration {
    authentication_configuration { access_role_arn = aws_iam_role.apprunner_ecr.arn }
    auto_deployments_enabled = true
    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_configuration { port = "3000" }
    }
  }
  instance_configuration {
    cpu    = "256"
    memory = "512"
  } # the smallest, cheapest size
  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
  }
}

# When finished, print the addresses we will need.
output "live_url"    { value = "https://${aws_apprunner_service.app.service_url}" }
output "ecr_url"     { value = aws_ecr_repository.app.repository_url }
output "deploy_role" { value = aws_iam_role.deploy.arn }
