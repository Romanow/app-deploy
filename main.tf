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

resource "digitalocean_database_connection_pool" "connection_pool" {
  cluster_id = digitalocean_database_cluster.postgres.id
  db_name    = var.database_name
  mode       = "transaction"
  name       = "${var.project_name}-connection-pool"
  size       = 10
  user       = var.database_user
  depends_on = [
    digitalocean_database_cluster.postgres,
    digitalocean_database_db.database,
    digitalocean_database_user.user
  ]
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

    static_site {
      name           = "frontend"
      build_command  = "npm run build"
      output_dir     = "build"
      index_document = "index.html"

      github {
        repo           = "Romanow/frontend-todo-list"
        branch         = "authorization"
        deploy_on_push = false
      }

      env {
        key   = "REACT_APP_BACKEND_IP"
        value = "/backend"
      }

      routes {
        path = "/"
      }
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
        value = digitalocean_database_connection_pool.connection_pool.host
      }

      env {
        key   = "DATABASE_PORT"
        value = digitalocean_database_connection_pool.connection_pool.port
      }

      env {
        key   = "DATABASE_NAME"
        value = digitalocean_database_connection_pool.connection_pool.name
      }

      env {
        key   = "DATABASE_USER"
        value = var.database_user
      }

      env {
        key   = "DATABASE_PASSWORD"
        value = digitalocean_database_connection_pool.connection_pool.password
        type  = "SECRET"
      }

      env {
        key   = "GOOGLE_CLIENT_ID"
        value = var.oauth2_credentials.client_id
        type  = "SECRET"
      }

      env {
        key   = "GOOGLE_CLIENT_SECRET"
        value = var.oauth2_credentials.client_secret
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