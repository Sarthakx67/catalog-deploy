data "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project_name}/${var.env}/vpc_id"
}
data "aws_ssm_parameter" "catalogue_sg_id" {
  name  = "/${var.project_name}/${var.env}/catalogue_sg_id"
}
data "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/${var.project_name}/${var.env}/private_subnet_ids"
}
data "aws_ssm_parameter" "app_alb_listener_arn" {
  name  = "/${var.project_name}/${var.env}/app_alb_listener_arn"
}
data "aws_ami" "roboshop-ami" {
  most_recent      = true
  name_regex       = "AlmaLinux OS 8.10.20240820 x86_64-c076b20a-2305-4771-823f-944909847a05"
  owners           = ["679593333241"]

  filter {
    name   = "name"
    values = ["AlmaLinux OS 8.10.20240820 x86_64-c076b20a-2305-4771-823f-944909847a05"]
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