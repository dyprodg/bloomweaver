terraform {
    backend "s3" {
        bucket = "bloomweaver-tfstate"
        key = "terraform.tfstate"
        region = "eu-central-1"
        encrypt = true
        use_lockfile = true
    }
}