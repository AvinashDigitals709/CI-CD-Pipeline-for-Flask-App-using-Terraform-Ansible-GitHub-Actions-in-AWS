terraform {
  backend "s3" {
    bucket = "avinash-tf-state"
    key    = "flask/terraform.tfstate"
    region = "us-east-1"
  }
}
