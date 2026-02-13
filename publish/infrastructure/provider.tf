terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "rear-admiral-signals"

  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "terraform"
      Product   = "camdenwander.com"
      Owner     = "Noise2Signal-LLC"
    })
  }
}

provider "aws" {
  alias   = "root"
  region  = "us-east-1"
  profile = "rear-admiral"

  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "terraform"
      Product   = "camdenwander.com"
      Owner     = "Noise2Signal-LLC"
    })
  }
}
