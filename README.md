
# Для начала работы я составил полный план того,что мне необходимо будет сделать:

![image](https://github.com/stanislavarutyunov/diplom/assets/119142863/c2693753-a924-4a78-9402-c26a40a1a22c)

1) ## Для развертки инфраструкты используем Terraform:
https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/main.tf

![Снимок экрана от 2023-06-07 21-31-40](https://github.com/stanislavarutyunov/diplom/assets/119142863/8227e0b3-5600-4363-a155-83905c798582)

![Снимок экрана от 2023-06-07 21-32-43](https://github.com/stanislavarutyunov/diplom/assets/119142863/3646e967-9e61-436e-bad0-2a5c5eb448a7)

![Снимок экрана от 2023-06-07 21-34-25](https://github.com/stanislavarutyunov/diplom/assets/119142863/e0019adb-b50f-41af-b684-a17f268c3924)

![Снимок экрана от 2023-06-07 21-35-46](https://github.com/stanislavarutyunov/diplom/assets/119142863/db9d0dad-cd73-43d2-8366-3e805339ea5f)

## Инициализируем TERRAFORM:

![terraforminit](https://github.com/stanislavarutyunov/diplom/assets/119142863/4e3df729-327b-4eb5-a290-df09755795c3)

Terraform validate:

![terrvalapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/01488034-5161-4e9b-9cca-d31585079bc8)


## Terraform apply:

![terrapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/663de513-8ff6-4978-ac18-769a2a66cccf)

Прописываем yes и инфраструктура создана. Все конфигурационные файлы,которые использовались для создания хостов,vpc и остальных сервисов в папке terraform.

https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/terraform/terraform.tfstate.backup

2) # Попадаем на наш бастион и пробрасываем ему ключи доступа для всех хостов

![Снимок экрана от 2023-06-10 08-35-43](https://github.com/stanislavarutyunov/diplom/assets/119142863/b519c6b6-b80c-4583-b74b-56a9e1221107)

![Снимок экрана от 2023-06-10 08-39-10](https://github.com/stanislavarutyunov/diplom/assets/119142863/653f0130-5d5b-4026-ab63-999dea5b40b8)


3) # С помощью ansible устанавливаем  и настраиваем необходимые сервисы на наших хостах:

https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/inventory/hosts.ini


![Снимок экрана от 2023-06-10 08-00-57](https://github.com/stanislavarutyunov/diplom/assets/119142863/c436114f-72ec-45c2-99cb-0e0bd6c1feff)


# Первый плейбук:

roles:
    - nginx
    - node_exporter
    - nginx_logexporter
    - filebeat


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


## Адрес сайта http://130.193.34.194/
 
 ### Настройки сайта(NGINX):


![Снимок экрана от 2023-06-10 09-29-53](https://github.com/stanislavarutyunov/diplom/assets/119142863/4db632b5-89bc-4203-8055-39a14ca23ea0)

![Снимок экрана от 2023-06-10 09-32-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/5d80a03a-4354-45c4-a9a0-af31616eb1cc)

![Снимок экрана от 2023-06-07 21-51-41](https://github.com/stanislavarutyunov/diplom/assets/119142863/cb156f59-d20b-40ae-9c84-b74f3998634b)

Сделаем проверку (`curl -v <публичный IP балансера>:80` ) :

![Снимок экрана от 2023-06-07 21-14-51](https://github.com/stanislavarutyunov/diplom/assets/119142863/3415162e-723a-4ca6-a8c0-572513422292)

Сайт я сделал интерактивным,при нажатии на ссылку kibana или grafana можно попасть на указанный нами ресурс:

![Снимок экрана от 2023-06-10 09-33-23](https://github.com/stanislavarutyunov/diplom/assets/119142863/8b754b08-5044-4f45-938a-a46c00ddb656)


# второй и третий  плейбуки:


https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/prometheus-playbook.yml

https://github.com/stanislavarutyunov/diplom/blob/main/netology-diplom/ansible/grafana-playbook.yml

## http://158.160.18.98:3000/login пароль admin

## http://158.160.69.207:3000/d/4aBQsjSmz34/nginx-servers-metrics111?orgId=1&refresh=1d

![Снимок экрана от 2023-06-10 09-02-45](https://github.com/stanislavarutyunov/diplom/assets/119142863/f698282e-42fe-43d3-8392-88e487b69cb0)

![grafana1](https://github.com/stanislavarutyunov/diplom/assets/119142863/ed66918d-1d03-4d93-95a6-ab6e5a52dead)

![grafana3](https://github.com/stanislavarutyunov/diplom/assets/119142863/c0212af0-2e3c-4b5d-8625-69bc81e5d101)

![Снимок экрана от 2023-06-10 07-59-27](https://github.com/stanislavarutyunov/diplom/assets/119142863/9c7fbec6-155c-4e7a-83b3-2c778841457f)

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
