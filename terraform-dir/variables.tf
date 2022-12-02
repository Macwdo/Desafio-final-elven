variable "region" {
    default = "us-east-1"
}

variable "profile" {
    default = "default"
}

variable "name_security_group" {
  default = "allow_ssh"
}

variable "name_security_group_mysql" {
  default = "MYSQL"
}


variable "vpc_id" {
  default = "vpc-032beb46262d17c93"
}

variable "ami_aws_instance" {
    default = "ami-0149b2da6ceec4bb0"
  
}

variable "type_aws_instance" {
  default = "t2.micro"
}

variable "key_aws_instance" {
    default = "Estudos-Macedo"
  
}

variable "engine_aws_db" {
  default = "mysql"
  
}

variable "engine_version_aws_db" {
  default = "5.7"
}

variable "instance_class_aws_db" {
  default =  "db.t2.micro"
  
}

variable "subnet_id_pub_a" {
  default = "subnet-0f6c379c4a1075e9e"
}

variable "subnet_id_pub_b" {
  default = "subnet-05378c61f6a6df7bd"
}

variable "subnet_id_priv_a" {
  default = "subnet-0b0a8331085fa48f0"
}

variable "subnet_id_priv_b" {
  default = "subnet-072caffa17fcad653"
}

