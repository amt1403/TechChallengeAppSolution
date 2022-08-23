##################################################
#-----------------Create Iam roles---------------#
##################################################

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${local.env}-${local.project}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "db_password_policy" {
  name   = "${local.env}-${local.project}-db-password-policy"
  policy = data.aws_iam_policy_document.db_password_policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "password_policy_attachment" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.db_password_policy.arn
}

##################################################
#------------Create network resources------------#
##################################################
resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr
  tags = {
    Name = "VPC of Project ECS"
  }
}

# igw for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${local.env}-${local.project}-igw"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${local.env}-${local.project}-eip"
  }
}

# nat for private subnets
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet_2a.id
  tags = {
    Name = "${local.env}-${local.project}-nat"
  }
}

resource "aws_route" "igw_route" {
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${local.env}-${local.project}-nat-rt"
  }

}

resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_subnet_2a.id
  route_table_id = aws_vpc.main_vpc.main_route_table_id
}
resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.public_subnet_2b.id
  route_table_id = aws_vpc.main_vpc.main_route_table_id
}
resource "aws_route_table_association" "public_2c" {
  subnet_id      = aws_subnet.public_subnet_2c.id
  route_table_id = aws_vpc.main_vpc.main_route_table_id
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_subnet_2a.id
  route_table_id = aws_route_table.nat_rt.id
}
resource "aws_route_table_association" "private_2b" {
  subnet_id      = aws_subnet.private_subnet_2b.id
  route_table_id = aws_route_table.nat_rt.id
}
resource "aws_route_table_association" "private_2c" {
  subnet_id      = aws_subnet.private_subnet_2c.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnetgroup"
  subnet_ids = [aws_subnet.private_subnet_2a.id, aws_subnet.private_subnet_2b.id, aws_subnet.private_subnet_2c.id]

  tags = {
    Name = "${local.env}-${local.project}-DB subnet group"
  }
}


#--------Create Public subnet for ELB

resource "aws_subnet" "public_subnet_2a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.cidr_1
  availability_zone       = var.az_2a
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.env}-${local.project}-public subnet 2a"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = true
  }
}

resource "aws_subnet" "public_subnet_2b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.cidr_2
  availability_zone       = var.az_2b
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.env}-${local.project}-public subnet 2b"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = true
  }
}

resource "aws_subnet" "public_subnet_2c" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.cidr_3
  availability_zone       = var.az_2c
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.env}-${local.project}-public subnet 2c"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = true
  }
}

#--------Create Private subnets for ECS and RDS

resource "aws_subnet" "private_subnet_2a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.cidr_4
  availability_zone = var.az_2a

  tags = {
    Name        = "${local.env}-${local.project}-private subnet 2a"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = false
  }
}

resource "aws_subnet" "private_subnet_2b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.cidr_5
  availability_zone = var.az_2b

  tags = {
    Name        = "${local.env}-${local.project}-private subnet 2b"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = false
  }
}

resource "aws_subnet" "private_subnet_2c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.cidr_6
  availability_zone = var.az_2c

  tags = {
    Name        = "${local.env}-${local.project}-private subnet 2c"
    Environment = "${local.env}"
    Project     = "${local.project}"
    Public      = false
  }
}

#--------Security Graoups

# allow public access to elb
resource "aws_security_group" "load_balancer_security_group" {
  name   = "${local.env}-${local.project}-elb-sg"
  vpc_id = aws_vpc.main_vpc.id
  ingress {
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
}

# allow app port from elb sg
resource "aws_security_group" "ecs_security_group" {
  name   = "${local.env}-${local.project}-ecs-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# allow db traffic from ecs sg
resource "aws_security_group" "db_security_group" {
  name   = "${local.env}-${local.project}-db-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

##################################################
#-----------------Create secrets-----------------#
##################################################

# generate random password for db, could be replaced with an existing secret
resource "random_password" "password" {
  length  = 12
  special = false
}

resource "aws_secretsmanager_secret_version" "secret_password" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.password.result
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "${local.env}-${local.project}-db-password-secret"
}