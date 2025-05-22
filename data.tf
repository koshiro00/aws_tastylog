data "aws_prefix_list" "s3_pl" {
  name = "com.amazonaws.*.s3"
}


data "aws_ami" "app" {
  most_recent = true               # 最新のAMIを取得
  owners      = ["self", "amazon"] # 自分のアカウントとAmazonのAMIを取得

  filter {
    name   = "name"
    values = ["al2023-ami-2023.7.20250512.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}