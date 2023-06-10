
#  Дипломная работа по профессии «Системный администратор»

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------
## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/).

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible. 

Параметры виртуальной машины (ВМ) подбирайте по потребностям сервисов, которые будут на ней работать. 

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Prometheus. На каждую ВМ из веб-серверов установите Node Exporter и [Nginx Log Exporter](https://github.com/martin-helmich/prometheus-nginxlog-exporter). Настройте Prometheus на сбор метрик с этих exporter.

Создайте ВМ, установите туда Grafana. Настройте её на взаимодействие с ранее развернутым Prometheus. Настройте дешборды с отображением метрик, минимальный набор — Utilization, Saturation, Errors для CPU, RAM, диски, сеть, http_response_count_total, http_response_size_bytes. Добавьте необходимые [tresholds](https://grafana.com/docs/grafana/latest/panels/thresholds/) на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Prometheus, Elasticsearch поместите в приватные подсети. Сервера Grafana, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.




Для начала работы я составил полный план того,что мне необходимо будет сделать:

![image](https://github.com/stanislavarutyunov/diplom/assets/119142863/c2693753-a924-4a78-9402-c26a40a1a22c)

1) Для развертки инфраструкты используем Terraform:

![Снимок экрана от 2023-06-07 21-31-40](https://github.com/stanislavarutyunov/diplom/assets/119142863/8227e0b3-5600-4363-a155-83905c798582)

![Снимок экрана от 2023-06-07 21-32-43](https://github.com/stanislavarutyunov/diplom/assets/119142863/3646e967-9e61-436e-bad0-2a5c5eb448a7)

![Снимок экрана от 2023-06-07 21-34-25](https://github.com/stanislavarutyunov/diplom/assets/119142863/e0019adb-b50f-41af-b684-a17f268c3924)

![Снимок экрана от 2023-06-07 21-35-46](https://github.com/stanislavarutyunov/diplom/assets/119142863/db9d0dad-cd73-43d2-8366-3e805339ea5f)

Инициализируем TERRAFORM:

![terraforminit](https://github.com/stanislavarutyunov/diplom/assets/119142863/4e3df729-327b-4eb5-a290-df09755795c3)

Terraform validate:

![terrvalapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/01488034-5161-4e9b-9cca-d31585079bc8)

Terraform apply:

![terrapply](https://github.com/stanislavarutyunov/diplom/assets/119142863/663de513-8ff6-4978-ac18-769a2a66cccf)

Прописываем yes и инфраструктура создана. Все конфигурационные файлы,которые использовались для создания хостов,vpc и остальных сервисов в папке terraform.

2) С помощью ansible устанавливаем  и настраиваем необходимые сервисы на наших хостах:

![Снимок экрана от 2023-06-10 08-00-57](https://github.com/stanislavarutyunov/diplom/assets/119142863/c436114f-72ec-45c2-99cb-0e0bd6c1feff)

Первый плейбук:

![Снимок экрана от 2023-06-10 08-02-15](https://github.com/stanislavarutyunov/diplom/assets/119142863/065a39f4-afd4-4443-b632-14617da8f161)

![nginxplay](https://github.com/stanislavarutyunov/diplom/assets/119142863/17e254d5-df08-44f6-8923-4b7b0f2d70d0)

![nginxlog_exporter](https://github.com/stanislavarutyunov/diplom/assets/119142863/b74cd4f0-57aa-445d-ae5c-fe01d922b4db)

![nginxserv](https://github.com/stanislavarutyunov/diplom/assets/119142863/f5c315c3-e1c3-47d8-8bdc-db66f0fbaba6)

![nodeexpserv](https://github.com/stanislavarutyunov/diplom/assets/119142863/89a888c8-5e7c-410b-90d7-747005674fc9)

![filebeat](https://github.com/stanislavarutyunov/diplom/assets/119142863/25b696ad-4acb-4c3a-89c9-10578ca8989f)


Адрес сайта http://130.193.34.194/

![Снимок экрана от 2023-06-07 21-51-41](https://github.com/stanislavarutyunov/diplom/assets/119142863/cb156f59-d20b-40ae-9c84-b74f3998634b)

Сделаем проверку (`curl -v <публичный IP балансера>:80` ) :

![Снимок экрана от 2023-06-07 21-14-51](https://github.com/stanislavarutyunov/diplom/assets/119142863/3415162e-723a-4ca6-a8c0-572513422292)


Сайт я сделал интерактивным,при нажатии на ссылку kibana или grafana можно попасть на указанный нами ресурс:

http://158.160.18.98:3000/login пароль admin

![grafana1](https://github.com/stanislavarutyunov/diplom/assets/119142863/d2612b82-1e66-4f8b-bb3c-c2c63afa8c64)

![grafana2](https://github.com/stanislavarutyunov/diplom/assets/119142863/4fc454eb-c2d9-4be8-9337-a544ca2b874f)


![Снимок экрана от 2023-06-10 08-14-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/f611418b-b53d-4ffe-ac8a-4e0e6f19cceb)


![grafana3](https://github.com/stanislavarutyunov/diplom/assets/119142863/c0212af0-2e3c-4b5d-8625-69bc81e5d101)


![prometheus-nginxlog-exporter](https://github.com/stanislavarutyunov/diplom/assets/119142863/bf12fa1a-1da9-4368-88f2-92815e037240)

![Снимок экрана от 2023-06-10 07-59-27](https://github.com/stanislavarutyunov/diplom/assets/119142863/9c7fbec6-155c-4e7a-83b3-2c778841457f)

http://158.160.0.12:5601/app/home#/ -Kibana

![Снимок экрана от 2023-06-10 08-14-08](https://github.com/stanislavarutyunov/diplom/assets/119142863/3a28b7c8-4b16-40a2-915b-de478645a297)

![image](https://github.com/stanislavarutyunov/diplom/assets/119142863/5e6a3c50-fef0-49e3-a8b4-cc2c28714d52)


