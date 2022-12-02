terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.3.5"
}


provider "aws" {
  profile = var.profile  
  region  = var.region
}


resource "aws_security_group" "allow_ssh" {
  name        = var.name_security_group
  description = "allow_ssh traffic"
  vpc_id      = var.vpc_id

ingress  {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "Memcache"
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3031
    to_port     = 3031
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodeExporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "MYSQL"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SSH"
  }
}


resource "aws_instance" "instancia1" {
  ami                         = var.ami_aws_instance
  instance_type               = var.type_aws_instance
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = var.key_aws_instance
  user_data = <<-EOF
              #!/bin/bash
              sudo su -
              sudo apt update && sudo apt install curl ansible unzip -y 
              sudo apt install docker docker-compose -y
              wget https://terraform-ansiblebucket-desafio-final.s3.amazonaws.com/main.zip
              unzip main.zip
              sudo ansible-playbook ansible-dir/wordpress.yml --extra-vars "mysql_host=${aws_db_instance.banco.address} memcached_endpoint=${aws_elasticache_cluster.memcache.cluster_address}"
              wget https://terraform-ansiblebucket-desafio-final.s3.amazonaws.com/docker-depends.zip
              unzip docker-depends.zip
              cd docker-depends/
              docker-compose up
              EOF
  monitoring                  = true
  subnet_id                   = var.subnet_id_pub_a
  associate_public_ip_address = true


  tags = {
    Name = "Maquina com wp1"
  }
}

resource "aws_instance" "instancia2" {
  ami                         = var.ami_aws_instance
  instance_type               = var.type_aws_instance
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = var.key_aws_instance
  user_data = <<-EOF
              #!/bin/bash
              sudo su -
              sudo apt update && sudo apt install curl ansible unzip -y 
              sudo apt install docker docker-compose -y
              wget https://terraform-ansiblebucket-desafio-final.s3.amazonaws.com/main.zip
              unzip main.zip
              sudo ansible-playbook ansible-dir/wordpress.yml --extra-vars "mysql_host=${aws_db_instance.banco.address} memcached_endpoint=${aws_elasticache_cluster.memcache.cluster_address}"
              wget https://terraform-ansiblebucket-desafio-final.s3.amazonaws.com/docker-depends.zip
              unzip docker-depends.zip
              cd docker-depends/
              docker-compose up
              EOF
  monitoring                  = true
  subnet_id                   = var.subnet_id_pub_b
  associate_public_ip_address = true

  tags = {
    Name = "Maquina com wp2"
  }
}


resource "aws_db_subnet_group" "db_subnet"{
  name = "dbsubnet"
  subnet_ids = [var.subnet_id_priv_a, var.subnet_id_priv_b]
}

resource "aws_db_instance" "banco" {
  allocated_storage = 20
  engine = var.engine_aws_db
  engine_version = var.engine_version_aws_db
  instance_class = var.instance_class_aws_db
  name = "wordpressbanco"
  username = "bancouser"
  password = "bancouserpass123"
  skip_final_snapshot = true 
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
}

resource "aws_elasticache_subnet_group" "subnet_cluster" {
  name       = "subnet-cluster"
  subnet_ids = [var.subnet_id_priv_a, var.subnet_id_priv_b]
}

resource "aws_elasticache_cluster" "memcache" {
  cluster_id           = "terraform-cluster"
  engine               = "memcached"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.6"
  port                 = 11211
  subnet_group_name    = aws_elasticache_subnet_group.subnet_cluster.name
  security_group_ids   = [aws_security_group.allow_ssh.id]
}

resource "aws_autoscaling_group" "terraform-autoscale" {
  min_size             = 1
  desired_capacity     = 2
  max_size             = 4
  launch_configuration = aws_launch_configuration.autoscale-config.id
  target_group_arns = [aws_lb_target_group.target-terraform.id]
  vpc_zone_identifier  = [var.subnet_id_pub_a, var.subnet_id_pub_b]
  health_check_type = "EC2"
  name = "wordpress"

  tag {
    key                 = var.key_aws_instance
    propagate_at_launch = false
    value               = "terraform-autoscale"
  }
}


resource "aws_launch_configuration" "autoscale-config" {
  image_id        = var.ami_aws_instance
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_ssh.id]
  key_name        = var.key_aws_instance

}


resource "aws_lb" "lb" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [var.subnet_id_pub_a, var.subnet_id_pub_b]

  enable_deletion_protection = false

  tags = {
    Environment = "network_lb"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-terraform.arn
  }
}


resource "aws_lb_target_group" "target-terraform" {
  name        = "terraform-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
      health_check {
        protocol = "HTTP"
        path = "/"
      }
}

resource "aws_lb_target_group_attachment" "target-group-instance" {
  target_group_arn = aws_lb_target_group.target-terraform.arn
  target_id        = aws_instance.instancia1.id
  port             = 80
}