resource "aws_instance" "mongodb_instance" {
  ami           = data.aws_ami.roboshop-ami.id
  instance_type = "t2.micro"
  key_name = "EC2-key"
  //user_data = filebase64("catalogue.sh")
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id = element(split(",",data.aws_ssm_parameter.private_subnet_ids.value), 0)
  tags = {
    Name = "Catalogue-DEV-AMI"
  }
}