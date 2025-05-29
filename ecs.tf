resource "aws_ecs_task_definition" "esrm" {
  family                   = ""
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = var.role

  container_definitions = jsonencode([
    {
      name      = "dkr-dev",
      image     = var.image,
      cpu       = 0,
      essential = true,
      readonlyRootFilesystem = true,

      portMappings = [
        {
          name          = "dev-80-tcp",
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp",
          appProtocol   = "http"
        }
      ],

      mountPoints = [
        {
          sourceVolume  = "nginx-run",
          containerPath = "/var/run",
          readOnly      = false
        },
        {
          sourceVolume  = "nginx-cache",
          containerPath = "/var/cache/nginx",
          readOnly      = false
        },
        {
          sourceVolume  = "nginx-temp",
          containerPath = "/var/tmp",
          readOnly      = false
        }
      ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/task-dev",
          awslogs-region        = "us-east-2",
          awslogs-stream-prefix = "ecs",
          awslogs-create-group  = "true",
          mode                  = "non-blocking",
          max-buffer-size       = "25m"
        }
      }
    }
  ])

  volume {
    name = "nginx-run"
    host_path = null
  }

  volume {
    name = "nginx-cache"
    host_path = null
  }

  volume {
    name = "nginx-temp"
    host_path = null
  }

  tags = {
    Name        = "taskdef-dev"

  }
}
