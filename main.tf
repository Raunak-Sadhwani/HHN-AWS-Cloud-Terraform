resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.firstbucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.firstbucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# make bucket public 
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.firstbucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# make bucket acl public
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.firstbucket.id
  acl    = var.bucket_acl
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.firstbucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.firstbucket.arn}/*"
      }
    ]
  })
}

data "template_file" "webapp_index" {
  template = file("${path.module}/webapp/index.html")  # Reference to the index.html file

  vars = {
    api_url = "https://${aws_apprunner_service.my_apprunner_service.service_url}/"
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.firstbucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = data.template_file.webapp_index.rendered
}

resource "aws_s3_bucket_website_configuration" "exampleindex" {
  bucket = aws_s3_bucket.firstbucket.id
  index_document {
    suffix = "index.html"
  }
  depends_on = [aws_s3_bucket_acl.example]
}


output "bucket_url" { 
  value = aws_s3_bucket.firstbucket.website_endpoint
}

resource "aws_ecr_repository" "my_repository" {
  name = var.repo_name
  image_tag_mutability = "MUTABLE"
  force_delete = true
}

resource "aws_iam_role" "app_runner_ecr_role" {
  name = "app-runner-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.app_runner_ecr_role.name
}

resource "aws_iam_role_policy" "ecr_login_policy" {
  name = "ecr-login-policy"
  role = aws_iam_role.app_runner_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "null_resource" "git_sha" {
  provisioner "local-exec" {
    command = "git rev-parse --short HEAD > git_sha.txt"
  }
}

data "local_file" "git_sha" {
  filename = "${path.module}/git_sha.txt"
  depends_on = [null_resource.git_sha]
}

locals {
  git_sha = chomp(trimspace(data.local_file.git_sha.content))
}

resource "aws_apprunner_service" "my_apprunner_service" {
  service_name = "my-apprunner-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_ecr_role.arn
    }

    image_repository {
      image_identifier      = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:${local.git_sha}"
      image_repository_type = "ECR"
      image_configuration {
        port = "80"
      }
    }
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }
}

resource "null_resource" "docker_image" {
  provisioner "local-exec" {
    command = "docker build -t ${var.repo_name}:${local.git_sha} . && docker tag ${var.repo_name}:${local.git_sha} ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:${local.git_sha} && docker push ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:${local.git_sha}"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [aws_ecr_repository.my_repository]
}

output "service_url" {
  value = aws_apprunner_service.my_apprunner_service.service_url
}