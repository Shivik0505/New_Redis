variable "public-sg-id" {
  type = string
}

variable "private-sg-id" {
  type = string
}

variable "pub-sub-id" {
  type = string  
}

variable "pri-sub-1-id" {
  type = string  
}

variable "pri-sub-2-id" {
  type = string  
}

variable "pri-sub-3-id" {
  type = string
}

variable "ami-id" {
  type = string
  default = "redis-demo-key"
}

variable "instance-type" {
  type = string
  default = "redis-demo-key"
}

variable "key-name" {
  type = string
  default = "redis-demo-key"
}
