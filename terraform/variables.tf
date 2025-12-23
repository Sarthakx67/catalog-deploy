variable "common_tags" {
  default = {
    Project = "roboshop"
    component = "catalogue"
    Environment = "DEV"
    Terraform = "true"
  }
}
variable "project_name" {
  default = "roboshop"
}
variable "env" {
  default = "dev"
}
variable "app_version" {
  default = "100.100.100"
}
variable "domain_name" {
  default = "stallions.space"
}