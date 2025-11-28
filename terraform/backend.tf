terraform {
  backend "s3" {
    bucket = "terraform-state-avinash-backend"
    key    = "flask/terraform.tfstate"
    region = "us-east-1"
  }
}
