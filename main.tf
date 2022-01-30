provider "digitalocean" {
  token = var.do_token
}

terraform {
  backend "local" {}
}

resource "digitalocean_database_cluster" "postgres" {
  name       = "postgres"
  engine     = "pg"
  version    = var.database.version
  size       = var.database.size
  region     = var.database.region
  node_count = 1
}

resource "digitalocean_database_db" "database" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.database_name
}

resource "digitalocean_database_user" "user" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.database_user
}

resource "digitalocean_app" "application" {
  spec {
    name   = "${var.project_name}-app"
    region = var.backend.region
    domain {
      name = "${var.project_name}.${var.domain}"
      zone = var.domain
      type = "PRIMARY"
    }

    service {
      name               = "backend"
      instance_count     = 1
      instance_size_slug = var.backend.size
      http_port          = var.backend.port

      image {
        registry_type = "DOCKER_HUB"
        registry      = var.backend.image.repository
        repository    = var.backend.image.name
        tag           = var.backend.image.tag
      }

      env {
        key   = "SPRING_PROFILES_ACTIVE"
        value = var.backend.profile
      }

      env {
        key   = "DATABASE_URL"
        value = digitalocean_database_cluster.postgres.host
      }

      env {
        key   = "DATABASE_PORT"
        value = digitalocean_database_cluster.postgres.port
      }

      env {
        key   = "DATABASE_NAME"
        value = var.database_name
      }

      env {
        key   = "DATABASE_USER"
        value = var.database_user
      }

      env {
        key   = "DATABASE_PASSWORD"
        value = digitalocean_database_user.user.password
        type  = "SECRET"
      }

      health_check {
        http_path             = "/manage/health"
        initial_delay_seconds = 20
        period_seconds        = 5
        success_threshold     = 1
        failure_threshold     = 10
      }

      routes {
        path = "/backend"
      }
    }
  }
}

resource "digitalocean_database_firewall" "firewall" {
  cluster_id = digitalocean_database_cluster.postgres.id
  rule {
    type  = "app"
    value = digitalocean_app.application.id
  }
}