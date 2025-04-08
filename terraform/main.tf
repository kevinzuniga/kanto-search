# 1. VPC y red básica
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# 2. Security group para ECS Fargate
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
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

# 3. Redis (Valkey) y grupo de subred
resource "aws_elasticache_subnet_group" "valkey" {
  name       = "valkey-subnet-group"
  subnet_ids = [aws_subnet.public.id]
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id       = "valkey-cluster"
  description                = "Valkey replication group"
  engine                     = "valkey"
  node_type                  = "cache.t2.micro"
  num_cache_clusters         = 1
  parameter_group_name       = "default.valkey8"
  subnet_group_name          = aws_elasticache_subnet_group.valkey.name
  security_group_ids         = [aws_security_group.ecs_sg.id]
  automatic_failover_enabled = false
}

# 4. Secrets (asumes que ya existen)
data "aws_secretsmanager_secret" "valkey_secret" {
  name = "valkey-redis-secret"
}

resource "aws_secretsmanager_secret_version" "valkey_secret_version" {
  secret_id     = data.aws_secretsmanager_secret.valkey_secret.id
  secret_string = jsonencode({ host = aws_elasticache_replication_group.valkey.primary_endpoint_address })
}

# 5. ECR
resource "aws_ecr_repository" "kanto_repo" {
  name = "kanto-search-repo"
}

# 6. IAM Role para ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 7. ECS Cluster
resource "aws_ecs_cluster" "kanto_cluster" {
  name = "kanto-search-cluster"
}

# 8. ECS Task Definition
resource "aws_ecs_task_definition" "kanto_task" {
  family                   = "kanto-search-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "kanto-search-container",
      image     = "${aws_ecr_repository.kanto_repo.repository_url}:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 3000,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "NODE_ENV",
          value = "production"
        }
      ]
    }
  ])
}

# 9. ECS Service
resource "aws_ecs_service" "kanto_service" {
  name            = "kanto-search-service"
  cluster         = aws_ecs_cluster.kanto_cluster.id
  task_definition = aws_ecs_task_definition.kanto_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.kanto_task]
}