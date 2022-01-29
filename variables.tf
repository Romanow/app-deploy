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
  default     = {
    size    = "db-s-1vcpu-1gb"
    region  = "ams3"
    version = 13
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

variable "domain" {
  description = "Domain for project"
  type        = string
  default     = "todo-list.romanow-alex.ru"
}