provider "digitalocean" {
  token = var.do_token
}

terraform {
  backend "local" {}
}

# Environment Variables
# Frontend
# – REACT_APP_BACKEND_IP = /backend
# Backend
# – SPRING_PROFILES_ACTIVE
# – DATABASE_URL
# – DATABASE_PORT
# – DATABASE_NAME
# – DATABASE_USER
# – DATABASE_PASSWORD
# – GOOGLE_CLIENT_ID
# – GOOGLE_CLIENT_SECRET
