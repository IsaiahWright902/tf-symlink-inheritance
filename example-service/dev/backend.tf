terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org"

    workspaces {
      name = "example-service-dev"
    }
  }

  required_version = ">= 1.7.5"
}
