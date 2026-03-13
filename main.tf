locals {

  name = "test"
}
// Creating a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.name}-vpc"
  }
}

// Creating a public subnet
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${local.name}-subnet-1"
  }
}

// Creating a private subnet
resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "${local.name}-subnet-2"
  }
}

//Creating an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}

// Creating an Elastic IP for the NAT Gateway
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}

// Creating a NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet1.id
  tags = {
    Name = "${local.name}-nat-gw"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

//Creating a public route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.name}-pub-rt"
  }
}

//Creating route table association for public subnet
resource "aws_route_table_association" "pub-rt-assoc" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.pub_rt.id
}

//Creating a private route table
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "${local.name}-pri-rt"
  }
}

//Creating route table association for private subnet
resource "aws_route_table_association" "pri-rt-assoc" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.pri_rt.id
}

// Creating a security group for ansible 
resource "aws_security_group" "ansible_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "This is my Ansible security group"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name}-ansible-sg"
  }
}

// Creating a security group for manage nodes
resource "aws_security_group" "managenodes_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "This is my manage nodes security group"
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name}-managenodes-sg"
  }
}

// Creating a key pair for ansible
resource "aws_key_pair" "key_pair" {
  key_name   = "ansible-key"
  public_key = file("./ansible-key.pem.pub")
}

// Creating an Ansible instance
resource "aws_instance" "ansible_instance" {
  ami                         = "ami-03446a3af42c5e74e" //ubuntu
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = aws_key_pair.key_pair.id
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  user_data                   = file("./user-data.sh")
  tags = {
    Name = "${local.name}-ansible-instance"
  }
}

// Creating an managed node 1 instance
resource "aws_instance" "ubuntu" {
  ami                         = "ami-03446a3af42c5e74e" //ubuntu
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = aws_key_pair.key_pair.id
  vpc_security_group_ids      = [aws_security_group.managenodes_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "${local.name}-ubuntu-node"
  }
}

// Creating an managed node 2 instance
resource "aws_instance" "redhat" {
  ami                         = "ami-0da543a6b4536a9e2" //redHat
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  key_name                    = aws_key_pair.key_pair.id
  vpc_security_group_ids      = [aws_security_group.managenodes_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "${local.name}-redhat-node"
  }
}
