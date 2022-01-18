resource "aws_instance" "cmdbuild_server" {
  count                       = 1
  ami                         = var.ami_name
  instance_type               = var.type
  subnet_id                   = var.subnetid
  security_groups             = [var.sgid]
  key_name                    = var.keyname
  user_data                   = file("setup_cmdbuild.sh")
  iam_instance_profile        = "Amazon-SSM"
  associate_public_ip_address = true
  tags = {
    Name = "cmdbuild"
  }
}

output "cmbuild_url" {
  value = join(":", [aws_instance.cmdbuild_server[0].public_ip, "443/cmdbuild"])
}
