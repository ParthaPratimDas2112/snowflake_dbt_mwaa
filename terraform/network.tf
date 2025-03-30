# Create a VPC for MWAA
resource "aws_vpc" "mwaa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "mwaa-vpc"
  }
}

# Create two private subnets in different availability zones
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = {
    Name = "mwaa-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  
  tags = {
    Name = "mwaa-private-subnet-2"
  }
}

# Create a public subnet for NAT Gateway
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "mwaa-public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mwaa_vpc.id
  
  tags = {
    Name = "mwaa-igw"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mwaa_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "mwaa-public-rt"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "mwaa-nat-eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  
  tags = {
    Name = "mwaa-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create route table for private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.mwaa_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  
  tags = {
    Name = "mwaa-private-rt"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create security group for MWAA
resource "aws_security_group" "mwaa_sg" {
  name        = "mwaa-security-group"
  description = "Security group for MWAA environment"
  vpc_id      = aws_vpc.mwaa_vpc.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "mwaa-sg"
  }
}