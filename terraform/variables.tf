
variable "az_2a" {
  description = "The Availability Zone within Sydney region"
  type        = string
  default     = "ap-southeast-2a"
}
variable "az_2b" {
  description = "The Availability Zone within Sydney region"
  type        = string
  default     = "ap-southeast-2b"
}

variable "az_2c" {
  description = "The Availability Zone within Sydney region"
  type        = string
  default     = "ap-southeast-2c"
}

variable "cidr" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cidr_1" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.1.0/24"
}

variable "cidr_2" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cidr_3" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.3.0/24"
}

variable "cidr_4" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.4.0/24"
}

variable "cidr_5" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.5.0/24"
}

variable "cidr_6" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.6.0/24"
}

variable "app_port" {
  description = "applicaiton port number"
  type        = number
  default     = 3000
}

variable "dbuser" {
  description = "Db user name"
  type        = string
  default     = "rdsuser" # could be any user
}