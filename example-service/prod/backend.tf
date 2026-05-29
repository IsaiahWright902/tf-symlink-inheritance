terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org"

    workspaces {
      name = "example-service-prod"
    }
  }

  required_version = ">= 1.7.5"
}
