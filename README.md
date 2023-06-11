
# Задание можно посмотреть по ссылке:
## [SYS-DIPLOM](https://github.com/netology-code/sys-diplom)

# Для начала работы я составил полный план того,что мне необходимо будет сделать:

![image](https://github.com/stanislavarutyunov/diplom/assets/119142863/c2693753-a924-4a78-9402-c26a40a1a22c)

 # 1. Для развертки инфраструкты используем Terraform:

[MAIN.TF](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/main.tf)


<details>

```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "authtoken" {
  type = string
}

provider "yandex" {
  token     = var.authtoken
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
```
  </details>

Группы безопасности:

[SECURITYGROUPS](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/securitygroups.tf)


<details>
  
```
resource "yandex_vpc_security_group" "webservers-sg" {
  name        = "webserverssg"
  description = "Webservers security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    description    = "Rule1 for healthchecks"
    v4_cidr_blocks = ["198.18.235.0/24"]
    from_port      = 1
    to_port        = 32767
  }

  ingress {
    protocol       = "TCP"
    description    = "Rule2 for healthchecks"
    v4_cidr_blocks = ["198.18.248.0/24"]
    from_port      = 1
    to_port        = 32767
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for load balancer"
    security_group_id = yandex_vpc_security_group.loadbalancer.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule1 for metrics"
    security_group_id = yandex_vpc_security_group.prometheus-sg.id
    port              = 9100
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule2 for metrics"
    security_group_id = yandex_vpc_security_group.prometheus-sg.id
    port              = 4040
  }

  egress {
    protocol       = "ANY"
    description    = "Rule out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "prometheus-sg" {
  name        = "prometheussg"
  description = "Prometheus security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol          = "TCP"
    description       = "Rule for grafana"
    security_group_id = yandex_vpc_security_group.grafana-sg.id
    port              = 9090
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name        = "elasticsearchsg"
  description = "Elasticsearch security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol          = "TCP"
    description       = "Rule for kibana"
    security_group_id = yandex_vpc_security_group.kibana-sg.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for webservers"
    security_group_id = yandex_vpc_security_group.webservers-sg.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "grafana-sg" {
  name        = "grafanasg"
  description = "Grafana security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    description    = "Rule for all"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibanasg"
  description = "Kibana security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    description    = "Rule for all"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "loadbalancer" {
  name        = "loadbalancer1sg"
  description = "Load balancer security group"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    description    = "Rule for income"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  ```
 </details>
  
  Здесь мы создаем Бастион-хост, который будет доступен с нашего пк по ssh. С бастиона мы уже сможем попасть на все наши остальные хосты.
  
Снапшоты:

[SNAPSHOT.TF](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/snapshot.tf)

Переменные:

[VARIABLES.TF](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/variables.tf)


# Meta:

![Снимок экрана от 2023-06-10 09-42-26](https://github.com/stanislavarutyunov/diplom/assets/119142863/16f81977-023e-49fb-8dbd-da2889980e63)


## Инициализируем TERRAFORM:

![terraforminit](https://github.com/stanislavarutyunov/diplom/assets/119142863/4e3df729-327b-4eb5-a290-df09755795c3)

## Terraform validate:

![terrvalapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/01488034-5161-4e9b-9cca-d31585079bc8)


## Terraform apply:

![terrapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/663de513-8ff6-4978-ac18-769a2a66cccf)

### Прописываем yes и инфраструктура создана. Все конфигурационные файлы,которые использовались для создания хостов,vpc и остальных сервисов в папке terraform.

[TFSTATE](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/terraform.tfstate)


![Снимок экрана от 2023-06-10 09-41-07](https://github.com/stanislavarutyunov/diplom/assets/119142863/1f6f9049-ef2b-461f-bd80-76af53d65c66)

![Снимок экрана от 2023-06-10 09-41-42](https://github.com/stanislavarutyunov/diplom/assets/119142863/33975671-94b3-486e-bf8c-e32cc7f2d184)


![Снимок экрана от 2023-06-07 21-34-25](https://github.com/stanislavarutyunov/diplom/assets/119142863/e0019adb-b50f-41af-b684-a17f268c3924)

![Снимок экрана от 2023-06-07 21-35-46](https://github.com/stanislavarutyunov/diplom/assets/119142863/db9d0dad-cd73-43d2-8366-3e805339ea5f)

![Снимок экрана от 2023-06-10 09-37-59](https://github.com/stanislavarutyunov/diplom/assets/119142863/7aa130e8-8c11-4d21-a7dd-6ecd99ca3673)
 
 Terraform outputs:
Что было создано нами при помощи терраформа:
7 Виртуальных машин,Балансировщик, Target Group, Backend Group, HTTP-ROUTER

<details>

```
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

```
</details>


# 2. Попадаем на наш бастион и пробрасываем ему ключи доступа для всех хостов



```
ssh-add
Identity added: /home/stanislav/.ssh/id_rsa (stanislav@fedora)
ssh -A stanislav@158.160.11.91
ssh -A stanislav@192.168.1.32
ssh -A stanislav@192.168.2.25
 и так далее
```

![Снимок экрана от 2023-06-10 08-35-43](https://github.com/stanislavarutyunov/diplom/assets/119142863/b519c6b6-b80c-4583-b74b-56a9e1221107)

![Снимок экрана от 2023-06-10 08-39-10](https://github.com/stanislavarutyunov/diplom/assets/119142863/653f0130-5d5b-4026-ab63-999dea5b40b8)


# 3. С помощью ansible устанавливаем  и настраиваем необходимые сервисы на наших хостах:

![Снимок экрана от 2023-06-10 14-18-49](https://github.com/stanislavarutyunov/diplom/assets/119142863/ff1b02f4-e5fb-4307-a727-fa7c80b18014)

Список всех наших хостов:
Для доступа на все хосты используем "прокси" через наш Бастион:

[HOSTS.INI](https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/inventory/hosts.ini)


![Снимок экрана от 2023-06-10 08-00-57](https://github.com/stanislavarutyunov/diplom/assets/119142863/c436114f-72ec-45c2-99cb-0e0bd6c1feff)


# Первый плейбук:

roles:
    - nginx
    - node_exporter
    - nginx_logexporter
   
   ![Снимок экрана от 2023-06-10 14-17-24](https://github.com/stanislavarutyunov/diplom/assets/119142863/c7d9ebfa-1cb2-4271-a131-f9581d0685ba)
   
   -filebeat
   
   ![Снимок экрана от 2023-06-10 14-18-03](https://github.com/stanislavarutyunov/diplom/assets/119142863/d5bdcd5d-a2c0-450a-b91a-95c2194b5e48)



https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/servers-playbook.yml

![Снимок экрана от 2023-06-10 08-02-15](https://github.com/stanislavarutyunov/diplom/assets/119142863/065a39f4-afd4-4443-b632-14617da8f161)

![nginxplay](https://github.com/stanislavarutyunov/diplom/assets/119142863/17e254d5-df08-44f6-8923-4b7b0f2d70d0)

# NGINX:

![Снимок экрана от 2023-06-10 09-21-00](https://github.com/stanislavarutyunov/diplom/assets/119142863/25561929-883e-4458-b93e-b5bf5073e1a4)

# NGINXLOG_EXPORTER:

![nginxlog_exporter](https://github.com/stanislavarutyunov/diplom/assets/119142863/b74cd4f0-57aa-445d-ae5c-fe01d922b4db)

# NODE_EXPORTER:

![nodeexpserv](https://github.com/stanislavarutyunov/diplom/assets/119142863/89a888c8-5e7c-410b-90d7-747005674fc9)

# FILEBEAT:

![filebeat](https://github.com/stanislavarutyunov/diplom/assets/119142863/25b696ad-4acb-4c3a-89c9-10578ca8989f)

![Снимок экрана от 2023-06-10 09-19-27](https://github.com/stanislavarutyunov/diplom/assets/119142863/5f272295-08ec-4a2d-861b-e5ad42b616e2)

![Снимок экрана от 2023-06-10 09-36-00](https://github.com/stanislavarutyunov/diplom/assets/119142863/282bb975-7a02-4ceb-b328-a930a600a1f8)



## Адрес сайта: http://130.193.34.194/
 
 ### Настройки сайта(NGINX):


![Снимок экрана от 2023-06-10 09-29-53](https://github.com/stanislavarutyunov/diplom/assets/119142863/4db632b5-89bc-4203-8055-39a14ca23ea0)

![Снимок экрана от 2023-06-10 09-32-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/5d80a03a-4354-45c4-a9a0-af31616eb1cc)

![Снимок экрана от 2023-06-07 21-51-41](https://github.com/stanislavarutyunov/diplom/assets/119142863/cb156f59-d20b-40ae-9c84-b74f3998634b)

Сделаем проверку (`curl -v 130.193.34.194:80` ) :

![Снимок экрана от 2023-06-07 21-14-51](https://github.com/stanislavarutyunov/diplom/assets/119142863/3415162e-723a-4ca6-a8c0-572513422292)

Сайт я сделал интерактивным,при нажатии на ссылку kibana или grafana можно попасть на указанный нами ресурс:

![Снимок экрана от 2023-06-10 09-33-23](https://github.com/stanislavarutyunov/diplom/assets/119142863/8b754b08-5044-4f45-938a-a46c00ddb656)


# второй и третий  плейбуки:

```
- hosts: prometheus
  remote_user: stanislav
  become: yes
  become_method: sudo
  roles:
    - prometheus
```

![Снимок экрана от 2023-06-10 14-23-25](https://github.com/stanislavarutyunov/diplom/assets/119142863/92d0b631-d5cd-44e8-8961-493cc1555859)

Конфиг для Прометеуса:

<details>

```
 Sample config for Prometheus.

global:
  scrape_interval:     30s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 40s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'example'

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "node-exp-rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'nginx'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 30s
    scrape_timeout: 30s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets:
    {% for server in groups['webservers'] %} 
        - {{ server }}:4040 
    {% endfor %}

  - job_name: node
    # If prometheus-node-exporter is installed, grab stats about the local
    # machine by default.
    static_configs:
      - targets:     
    {% for server in groups['webservers'] %} 
        - {{ server }}:9100
    {% endfor %}
```
</details>
 
https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/prometheus-playbook.yml




```
- hosts: grafana
  remote_user: stanislav
  become: yes
  become_method: sudo
  vars:
    prometheus_ip: "{{ groups['prometheus'] | map('extract', hostvars, ['inventory_hostname']) | join ('') }}"
    grafana_ip: "{{ groups['grafana'] | map('extract', hostvars, ['inventory_hostname']) | join ('') }}"
  roles:
    - grafana
```


![Снимок экрана от 2023-06-10 14-24-12](https://github.com/stanislavarutyunov/diplom/assets/119142863/d89c8a54-a229-4a10-8580-e2ee21ee76dd)


https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/grafana-playbook.yml

## http://158.160.18.98:3000/login пароль admin


![Снимок экрана от 2023-06-10 09-02-45](https://github.com/stanislavarutyunov/diplom/assets/119142863/f698282e-42fe-43d3-8392-88e487b69cb0)

![grafana1](https://github.com/stanislavarutyunov/diplom/assets/119142863/ed66918d-1d03-4d93-95a6-ab6e5a52dead)

http://158.160.18.98:3000/d/4aBQsjSmz34/nginx-servers-metrics111?orgId=1&refresh=10s

![Снимок экрана от 2023-06-10 13-26-07](https://github.com/stanislavarutyunov/diplom/assets/119142863/f6d1f327-5237-4d71-85c9-c6a915d6d808)


![Снимок экрана от 2023-06-10 13-21-13](https://github.com/stanislavarutyunov/diplom/assets/119142863/116b66c5-e2b1-48ef-8c95-a31b1ea0cb1f)


# четвертый и пятый плейбуки:

В связи с санкциями и недостпуностью ELK,принял решение джелать их через Docker:

Elasticsearch:

![Снимок экрана от 2023-06-10 08-54-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/efe427f9-bb52-4c43-9ab9-9d73c474e3e5)

![Снимок экрана от 2023-06-10 09-17-23](https://github.com/stanislavarutyunov/diplom/assets/119142863/b7fba072-49cb-4d5c-ba27-20494b628b07)


https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/elasticsearch-playbook.yml

Kibana(перед запуском уже установил на нем докер) :

[Снимок экрана от 2023-06-10 08-54-46](https://github.com/stanislavarutyunov/diplom/assets/119142863/eb414866-d37e-42e0-a122-9c129630bac4)

https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/kibana-playbook.yml



## http://158.160.0.12:5601/app/home#/ -Kibana





![Снимок экрана от 2023-06-10 08-51-29](https://github.com/stanislavarutyunov/diplom/assets/119142863/85c3df60-3aad-47c2-8f9e-9b127e885a9e)


![Снимок экрана от 2023-06-10 08-14-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/3a28b7c8-4b16-40a2-915b-de478645a297)


![image](https://github.com/stanislavarutyunov/diplom/assets/119142863/5e6a3c50-fef0-49e3-a8b4-cc2c28714d52)


![Снимок экрана от 2023-06-10 08-57-45](https://github.com/stanislavarutyunov/diplom/assets/119142863/c18253cd-cc4c-48ea-ba46-652c4f8c1c18)


![Снимок экрана от 2023-06-10 08-58-46](https://github.com/stanislavarutyunov/diplom/assets/119142863/103fc671-e1b4-4ac9-b9b4-0370ce8fbd81)
