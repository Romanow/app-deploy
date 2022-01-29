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
  name       = var.database_name
}

resource "digitalocean_app" "application" {
  spec {
    name   = "todo-list-app"
    region = "ams3"
    domain {
      name = var.domain
    }

    service {
      name               = "backend"
      instance_count     = 1
      instance_size_slug = "basic-xxs"
      http_port          = 8080

      image {
        registry_type = "DOCKER_HUB"
        registry      = "romanowalex"
        repository    = "backend-todo-list"
        tag           = "v1.0-do"
      }

      env {
        key   = "DATABASE_URL"
        value = digitalocean_database_cluster.postgres.uri
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