terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}



}

provider "yandex" {
  token     = "xxxxxxxxx"
  cloud_id  = "b1g7stv2itkaoptc01to"
  folder_id = "b1gkdj4odgo1a0bjk09u"
}

resource "yandex_vpc_address" "staddr" {
  name = "balanceraddr"

  external_ipv4_address {
    zone_id = "ru-central1-b"
  }
}

resource "yandex_compute_instance" "webserver" {
  for_each = var.webserv
  name     = each.key
  zone     = each.value.zone

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 14
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.privatesubnet["${each.value.subnet}"].id
    security_group_ids = ["${yandex_vpc_security_group.webservers-sg.id}"]
  }

  metadata = {
    user-data = "${file("/home/stanislav/git/netology-diplom/terraform/meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-3" {
  name        = "prometheus"
  description = "prometheus_server"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 16
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.privatesubnet["prsubneta"].id
    security_group_ids = ["${yandex_vpc_security_group.prometheus-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-4" {
  name        = "grafana"
  description = "grafana_server"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 18
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.publicsubnet.id
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.grafana-sg.id}"]
  }

  metadata = {
    user-data = "${file("/home/stanislav/git/netology-diplom/terraform/meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-5" {
  name        = "elasticsearch"
  zone        = "ru-central1-b"
  description = "elasticsearch_server"

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.privatesubnet["prsubnetb"].id
    security_group_ids = ["${yandex_vpc_security_group.elasticsearch-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-6" {
  name        = "kibana"
  zone        = "ru-central1-b"
  description = "kibana_server"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 16
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.publicsubnet.id
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.kibana-sg.id}"]
  }

  metadata = {
    user-data = "${file("/home/stanislav/git/netology-diplom/terraform/meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-7" {
  name        = "bastionhost"
  zone        = "ru-central1-b"
  description = "bastion"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.publicsubnet.id
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.bastion.id}"]
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_vpc_subnet" "privatesubnet" {
  for_each       = var.subnetinfo
  name           = each.key
  zone           = each.value.zone
  v4_cidr_blocks = each.value.v4_cidr_blocks
  network_id     = yandex_vpc_network.network-1.id
  route_table_id = yandex_vpc_route_table.natroute.id
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "natroute" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "publicsubnet" {
  name           = "pubsubnet"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.3.0/24"]
}

resource "yandex_alb_target_group" "web-target" {
  name = "web-target-group"

  dynamic "target" {
    for_each = var.webserv
    content {
      subnet_id  = yandex_vpc_subnet.privatesubnet["${target.value.subnet}"].id
      ip_address = yandex_compute_instance.webserver["${target.key}"].network_interface.0.ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web-backend" {
  name = "web-backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.web-target.id}"]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web-router" {
  name = "webrouter"
  labels = {
    tf-label    = "tf-web-http-router"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "virtual-host" {
  name           = "vhrouter"
  http_router_id = yandex_alb_http_router.web-router.id
  route {
    name = "route1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-backend.id
        timeout          = "10s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web-load-balancer" {
  name               = "load-balancer"
  network_id         = yandex_vpc_network.network-1.id
  security_group_ids = ["${yandex_vpc_security_group.loadbalancer.id}"]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.privatesubnet["prsubneta"].id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.privatesubnet["prsubnetb"].id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.staddr.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}

output "external_ip_address_balancer" {
  value = yandex_alb_load_balancer.web-load-balancer.listener.*.endpoint.0.address.0.external_ipv4_address
}
output "internal_ip_address_web_1" {
  value = yandex_compute_instance.webserver["web1"].network_interface.0.ip_address
}

output "internal_ip_address_web_2" {
  value = yandex_compute_instance.webserver["web2"].network_interface.0.ip_address
}

output "internal_ip_address_vm_3" {
  value = yandex_compute_instance.vm-3.network_interface.0.ip_address
}

output "internal_ip_address_vm_4" {
  value = yandex_compute_instance.vm-4.network_interface.0.ip_address
}
output "external_ip_address_vm_4" {
  value = yandex_compute_instance.vm-4.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_5" {
  value = yandex_compute_instance.vm-5.network_interface.0.ip_address
}

output "internal_ip_address_vm_6" {
  value = yandex_compute_instance.vm-6.network_interface.0.ip_address
}
output "external_ip_address_vm_6" {
  value = yandex_compute_instance.vm-6.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_7" {
  value = yandex_compute_instance.vm-7.network_interface.0.ip_address
}
output "external_ip_address_vm_7" {
  value = yandex_compute_instance.vm-7.network_interface.0.nat_ip_address
}


