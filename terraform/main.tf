provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_elasticache_subnet_group" "redis" {
  name       = "valkey-subnet-group"
  subnet_ids = [aws_subnet.public.id]
}

resource "aws_elasticache_cluster" "valkey" {
  cluster_id           = "valkey-cluster"
  engine               = "valkey"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.valkey7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.ecs_sg.id]
}

resource "aws_secretsmanager_secret" "redis" {
  name = "valkey-redis-secret"
}

resource "aws_secretsmanager_secret_version" "redis_version" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({ host = aws_elasticache_cluster.valkey.cache_nodes[0].address })
}
