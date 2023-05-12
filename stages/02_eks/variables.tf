variable "key_pairs" {
  type = list(object({
    key_name   = string
    public_key = string
  }))
  default = [
    {
      key_name   = "NamDP"
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfus7XGzUwN..."
    },
    {
      key_name   = "ABC"
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfs6XGzUwN..."
    }
  ]
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = [for key_pair in var.key_pairs : key_pair.key_name]
  public_key = [for key_pair in var.key_pairs : key_pair.public_key]
}
