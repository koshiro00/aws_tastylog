# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "vpc" {
  cidr_block                       = "19.168.0.0/20"
  instance_tenancy                 = "default" # インスタンスのテナンシーをデフォルトに設定
  enable_dns_support               = true      # DNSサポートを有効にする
  enable_dns_hostnames             = true      # DNSホスト名を有効にする
  assign_generated_ipv6_cidr_block = false     # IPv6 CIDRブロックを割り当てない

  tags = {
    Name    = "${var.project}-${var.environment}-vpc"
    Project = var.project
    Env     = var.environment
  }
}

# ----------------------
# Subnet
# ----------------------
resource "aws_subnet" "public-subnet-1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1a" # アベイラビリティゾーン（東京リージョン）を指定
  cidr_block              = "19.168.1.0/24"
  map_public_ip_on_launch = true # パブリックIPを自動割り当て

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1a"
    Project = var.project
    Env     = var.environment
    type    = "public"
  }
}

resource "aws_subnet" "public-subnet-1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1c" # アベイラビリティゾーン（東京リージョン）を指定
  cidr_block              = "19.168.2.0/24"
  map_public_ip_on_launch = true # パブリックIPを自動割り当て

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1c"
    Project = var.project
    Env     = var.environment
    type    = "public"
  }
}

resource "aws_subnet" "private-subnet-1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1a" # アベイラビリティゾーン（東京リージョン）を指定
  cidr_block              = "19.168.3.0/24"
  map_public_ip_on_launch = false # パブリックIPを自動割り当てしない

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1a"
    Project = var.project
    Env     = var.environment
    type    = "private"
  }
}

resource "aws_subnet" "private-subnet-1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1c" # アベイラビリティゾーン（東京リージョン）を指定
  cidr_block              = "19.168.4.0/24"
  map_public_ip_on_launch = false # パブリックIPを自動割り当てしない

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1c"
    Project = var.project
    Env     = var.environment
    type    = "private"
  }
}

# ----------------------
# Route table
# ----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-public-rt"
    Project = var.project
    Env     = var.environment
    type    = "public"
  }
}

resource "aws_route_table_association" "public_rt_1a" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public-subnet-1a.id
}

resource "aws_route_table_association" "public_rt_1c" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public-subnet-1c.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-private-rt"
    Project = var.project
    Env     = var.environment
    type    = "private"
  }
}

resource "aws_route_table_association" "private_rt_1a" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private-subnet-1a.id
}

resource "aws_route_table_association" "private_rt_1c" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private-subnet-1c.id
}

# ----------------------
# Internet Gateway,
# ----------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-igw"
    Project = var.project
    Env     = var.environment
  }
}

# パブリックルートテーブルにインターネットへの経路を追加
resource "aws_route" "public_rt_igw_r" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0" # すべての行き先（トラフィック）を許可
  gateway_id             = aws_internet_gateway.igw.id
}