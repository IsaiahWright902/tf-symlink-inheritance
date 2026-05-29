terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org"

    workspaces {
      name = "example-service-qa"
    }
  }

  required_version = ">= 1.7.5"
}
