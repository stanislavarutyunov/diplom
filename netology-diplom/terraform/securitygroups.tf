# Security Groups
# Security bastion host

resource "yandex_vpc_security_group" "group-bastion-host" {
  name        = "My security group bastion host"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group to allow incoming ssh traffic
resource "yandex_vpc_security_group" "group-ssh-traffic" {
  name        = "My security group ssh traffic"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "ICMP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }
}

# Security group webservers
resource "yandex_vpc_security_group" "group-webservers" {
  name        = "My security group webservers"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 80
   # predefined_target = "loadbalancer_healthchecks"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "TCP"
    port           = 4040
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security group prometheus
resource "yandex_vpc_security_group" "group-prometheus" {
  name        = "My security group prometheus"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security group public network grafana
resource "yandex_vpc_security_group" "group-public-network-grafana" {
  name        = "My security group public network grafana"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["192.168.30.3/32"]
  }
}

# Security group elasticsearch
resource "yandex_vpc_security_group" "group-elasticsearch" {
  name        = "My security group elasticsearch"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }

  egress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
  }
}

# Security group public network kibana
resource "yandex_vpc_security_group" "group-public-network-kibana" {
  name        = "My security group public network kibana"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.30.22/32"]
  }
}

# Security group public application load balancer
resource "yandex_vpc_security_group" "group-public-network-alb" {
  name        = "My security group public network application load balancer"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
