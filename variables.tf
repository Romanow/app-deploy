variable "do_token" {
  description = "DigitalOcean token"
  type        = string
}

variable "database" {
  description = "Database parameters"
  type        = object({
    size    = string
    region  = string
    version = number
  })
  default = {
    size    = "db-s-1vcpu-1gb"
    region  = "ams3"
    version = 13
  }
}

variable "backend" {
  description = "Backend parameters"
  type        = object({
    size   = string
    region = string
    port   = number
    image  = object({
      repository = string
      name       = string
      tag        = string
    })
    profile = string
  })
  default = {
    size    = "basic-xxs"
    region  = "ams"
    port    = 8080
    profile = "do"
    image   = {
      repository = "romanowalex"
      name       = "backend-todo-list"
      tag        = "v1.0-do"
    }
  }
}

variable "frontend" {
  description = "Frontend parameters"
  type    = object({
    repository = string
    branch     = string
  })
  default = {
    repository = "Romanow/frontend-todo-list"
    branch = "authorization"
  }
}

variable "database_name" {
  description = "Database name for program"
  type        = string
  default     = "todo_list"
}

variable "database_user" {
  description = "Database program username"
  type        = string
  default     = "program"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "todo-list"
}

variable "domain" {
  description = "Base domain"
  type        = string
  default     = "romanow-alex.ru"
}

variable "oauth2_credentials" {
  description = "OAuth2 clientId and clientSecret"
  type        = object({
    client_id     = string
    client_secret = string
  })
}