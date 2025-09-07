# terraform {
#   backend "s3" {
#     bucket         = "devops-tfstate-dima-goit"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
