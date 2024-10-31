terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.73.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "masthan123"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "one" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "amazon-VPC"
  }
}

# Create Public Subnet for web-server-1
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "amazon-Web-subnet-1a"
  }
}

# Create Public Subnet for web-server-2
resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "amazon-Web-subnet-1b"
  }
}



# Create Private Subnet for app-server-1
resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "amazon-App-subnet-1a"
  }
}

# Create Private Subnet for app-server-2
resource "aws_subnet" "application-subnet-2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "amazon-App-subnet-1b"
  }
}

# Create Private Subnet for db-server-1
resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.one.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "amazon-DB-subnet-1a"
  }
}

# Create Private Subnet for db-server-2
resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.one.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "amazon-DB-subnet-lb"
  }
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "AMAZON-IGW"
  }
}


# Create Web layber route table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "WebRT"
  }
}


# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}

#Create WEB-SERVER-1 Instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-04e81358dc84d661d"
  instance_type          = "t2.micro"
  availability_zone      = "ap-south-1a"
  key_name               = "KeyName"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id
  user_data              = file("apache.sh")

  tags = {
    Name = "AMAZON-Web-Server-1"
  }
}

#Create WEB-SERVER-2 Instance
resource "aws_instance" "webserver2" {
  ami                    = "ami-04e81358dc84d661d"
  instance_type          = "t2.micro"
  availability_zone      = "ap-south-1b"
  key_name               = "KeyName"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  user_data              = file("apache.sh")

  tags = {
    Name = "AMAZON-Web-Server-2"
  }
}

#Create APP SERVER-1 EC2 Instance
resource "aws_instance" "appserver1" {
  ami                    = "ami-04e81358dc84d661d"
  instance_type          = "t2.micro"
  availability_zone      = "ap-south-1a"
  key_name               = "KeyName"
  vpc_security_group_ids = [aws_security_group.appserver-sg.id]
  subnet_id              = aws_subnet.application-subnet-1.id
  tags = {
    Name = "AMAZON-app-Server-1"
  }
}

#Create APP SERVER-2 EC2 Instance
resource "aws_instance" "appserver2" {
  ami                    = "ami-04e81358dc84d661d"
  instance_type          = "t2.micro"
  availability_zone      = "ap-south-1b"
  key_name               = "KeyName"
  vpc_security_group_ids = [aws_security_group.appserver-sg.id]
  subnet_id              = aws_subnet.application-subnet-2.id

  tags = {
    Name = "app Server-2"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Dinesh1122"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.id
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Create Web Security Group
resource "aws_security_group" "webserver-sg" {
  name        = "webserver-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "Web-SG"
  }
}

# Create Application Security Group
resource "aws_security_group" "appserver-sg" {
  name        = "appserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 22
    to_port     = 22
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
    Name = "appserver-SG"
  }
}

# Create Database Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Allow traffic from application layer"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}

#CREATE LOAD-BALANCER FOR AMAZON

resource "aws_lb" "external-elb" {
  name               = "AMAZON-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}




output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}


resource "aws_s3_bucket" "example" {
  bucket = "myownnewbuck01"
}


resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_group_membership" "team" {
  name = "tf-testing-group-membership"

  users = [
    aws_iam_user.user_one.name,
    aws_iam_user.user_two.name,
  ]

  group = aws_iam_group.group.name
}

resource "aws_iam_group" "group" {
  name = "test-group"
}

resource "aws_iam_user" "user_one" {
  name = "test-user"
}

resource "aws_iam_user" "user_two" {
  name = "test-user-two"
}
