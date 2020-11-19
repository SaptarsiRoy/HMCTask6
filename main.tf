#provider
provider "aws" {
    region = "ap-south-1"
    profile = "Sara"
  
}

#database password
variable "admin_password" {
    type = string
    description = "contains admin password"
    default="SaptarsiRoy"
}

# Getting default VPC
data "aws_vpc" "default_vpc" {
    default = true
}

# Getting default Subnets
data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Security Group for RDS Instance
resource "aws_security_group" "db_sg" {
  name        = "Security Group for RDS"
  description = "Connection between WordPress and RDS database server"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_sg"
  }
}

# Subnet Group for RDS
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds subnet group"
  subnet_ids = data.aws_subnet_ids.default_subnet.ids
}

#Deploy the RDS instance
resource "aws_db_instance" "mydb" {
    
    depends_on = [
        aws_security_group.db_sg,
        aws_db_subnet_group.rds_subnet,
    ]

    allocated_storage = 10
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    parameter_group_name = "default.mysql5.7"
    instance_class = "db.t2.micro"
    db_subnet_group_name   = aws_db_subnet_group.rds_subnet.id
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    publicly_accessible    = true
    name = "wpdb"
    username = "admin"
    password = var.admin_password
    skip_final_snapshot  = true
    auto_minor_version_upgrade = true
    port = 3306
}

#writing code for kubernetes 

provider "kubernetes"{
    load_config_file = false

    host = "https://192.168.99.100:8443"

  client_certificate     = file("C:\\Users\\KIIT\\.minikube\\profiles\\minikube\\client.crt")
  client_key             = file("C:\\Users\\KIIT\\.minikube\\profiles\\minikube\\client.key")
  cluster_ca_certificate = file("C:\\Users\\KIIT\\.minikube\\ca.crt")
}

resource "kubernetes_deployment" "wp" {
  depends_on = [ aws_db_instance.mydb ]
  metadata {
    name = "wordpress-deployment"
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
      spec {
        container {
          image = "wordpress:5.5"
          name  = "wp"
          env {
            name = "WORDPRESS_DB_HOST"
            value = aws_db_instance.mydb.endpoint
          }
          env {
                    name = "WORDPRESS_DB_DATABASE"
                    value = aws_db_instance.mydb.name 
                }
          env {
            name = "WORDPRESS_DB_USER"
            value = aws_db_instance.mydb.username
          }
          env {
            name = "WORDPRESS_DB_PASSWORD"
            value = var.admin_password
          }
          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          }
        }
      }
    }
  }

resource "kubernetes_service" "wp_service" {
  depends_on = [ kubernetes_deployment.wp ]
  metadata {
    name = "wp-service"
    labels = {
      "app" = "wordpress"
    }
  }
  spec {
    selector = {
      "app" = "wordpress"
    }
    port {
      port = 80
    }
    type = "NodePort"
 }
}

#checking if everythng is sucessfully deployed

resource "null_resource" "Chrome"  {
depends_on = [
    kubernetes_service.wp_service,
  ]

	provisioner "local-exec" {
	    command = "minikube service ${kubernetes_service.wp_service.metadata[0].name}"
  	}
}