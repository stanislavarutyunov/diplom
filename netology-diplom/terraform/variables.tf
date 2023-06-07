variable "subnetinfo" {
  type = map(any)
  default = {
    prsubneta = {
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["192.168.1.0/24"]
    },
    prsubnetb = {
      zone           = "ru-central1-b"
      v4_cidr_blocks = ["192.168.2.0/24"]
    }
  }
}

variable "webserv" {
  type = map(any)
  default = {
    web1 = {
      zone   = "ru-central1-a"
      subnet = "prsubneta"
    },
    web2 = {
      zone   = "ru-central1-b"
      subnet = "prsubnetb"
    }
  }
}

