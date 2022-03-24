variable "name" {
  description = "Used to name various infrastructure components"
  default     = "learn-nomad-edge"
}

variable "region" {
  description = "The AWS region to deploy to."
  default     = "us-east-1"
}

variable "ami" {
}

variable "client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.micro"
}

variable "targeted_client_instance_type" {
  description = "The AWS instance type to use for targeted clients."
  default     = "t2.micro"
}

variable "targeted_client_count" {
  description = "The number of targeted clients to provision."
  default     = "2"
}

variable "root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 16
}

variable "key_name" {
  description = "Name of the SSH key used to provision EC2 instances."
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "retry_join" {
  description = "Used by Consul to automatically form a cluster."
  type        = map(string)

  default = {
    provider  = "aws"
    tag_key   = "ConsulAutoJoinNomadEdge"
    tag_value = "auto-join"
  }
}

variable "nomad_binary" {
  description = "Used to replace the machine image installed Nomad binary."
  default     = "none"
}

variable "primary_security_group_id" {
  description = "Primary security group ID"
}

variable "client_security_group_id" {
  description = "Client security group ID"
}

variable "public_subnets" {
  description = "Public subnets"
}

variable "iam_instance_profile_name" {
  description = "IAM Instance profile name"
}

variable "nomad_server_ips" {
  description = "Nomad server IP address"
}

variable "nomad_targeted_dc" {
  description = "Targeted DC"
  default     = "dc3"
}

variable "nomad_dc" {
  description = "Targeted DC"
  default     = "dc1"
}