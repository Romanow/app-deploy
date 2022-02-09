# Как вывести приложение в prod, ~~почти ничего~~ не понимая в DevOps

## План доклада

1. Предположим, мы Senior Fullstack Developer, разработали небольшое приложение, состоящее из БД, backend и frontend и
   теперь мы хотим его задеплоить. Мы не очень стильные и модные, потому написали на стандартном стеке:
    1. backend: Kotlin + Spring;
    2. frontend: Typescript + React + Redux;
    3. Postgres.
2. Есть три основных варианта:
    1. VDS: Postgres на отдельной виртуалке, Spring Boot как Fat Jar завернуть в Systemd Unit, frontend собрать в
       статику и засунуть в nginx.<br>
       Но тут появляются проблемы: нужно разобраться на настраивать systemd, разобраться как работает nginx и настроить
       его на отдачу статики и upstream. Если backend будет на отдельной машине, то починить CORS. Установить Postgres,
       настроить pg_hba.conf, разобраться какие настройки в postgres.conf нужны, на что влияют и какие значения там
       описать. Плюс надо еще задуматься над безопасностью серверов, что вообще заоблачная задача.<br>
       Если вы во всем этом разберетесь, то ваш уровень знаний несомненно вырастет, но это сложная задача.
    2. K8S: Самостоятельно поднять и настроить кластер Kubernetes, задача очень сложная и требует больших знаний. Можно
       использовать Managed K8S Cluster, например в DigitalOcean, AWS или Яндекс.Облаке. Вы получаете полноценный
       кластер (иногда без master нод), от вас скрыты все нюансы настройки, безопасности, поддержки, вы просто берете и
       сразу работете. Вариант хороший, но все равно придется разобраться в устройстве K8S и написать все манифесты.
       Плюс кластер Managed K8S стоит дорого, т.к. вы платите за 3+ виртуалки, на которых этот кластер разворачивается.
    3. PaaS: DigitalOcean App (Heroku, Google App Engine, ...): Вы не заморачиваетесь с настройкой инфраструктуры
       вообще, просто описываете этапы сборки / деплоя вашего приложения, все остальное на себя забирает платформа. БД
       тоже можно получить как Managed Instance, т.е. погружаться в нюансы настройки Postgres вам не надо. Этот вариант
       не такой затратный по деньгам, т.к. вы фактически платите только за ресурсы, которые потребляет Postgres и ваш
       сервис, а это выходит значительно дешевле чем Managed K8S и сапоставимо с деплоем на чистые VDS сервера.
3. У нас есть наше приложение TODO List, состоящее из [backend](https://github.com/Romanow/todolist-backend)
   и [frontend](https://github.com/Romanow/todolist-frontend), рассмотрим как его быстро и легко задеплоить в
   DigitalOcean App. Для настройки инфраструктуры я буду использовать [Terraform](https://www.terraform.io/) –
   инструмент для декларативного описания ресурсов, реализующий концепцию IaaC.
4. Возьмем шаблон манифеста и допишем в него необходимые шаги.

Для установки Terraform воспользуемся утилитой [tfenv](https://github.com/tfutils/tfenv), которая устанавливает
последнюю версию terraform или берет нужную из файла [.terraform-version](.terraform-version):

```shell
$ brew install tfenv
$ tfenv install
```

Итак, terraform установлен, нам надо инициализировать [провайдер DigitalOcean](versions.tf) для Terraform. Для этого нам
нужно API KEY ([получение](https://docs.digitalocean.com/reference/api/create-personal-access-token/)) прописать либо в
OS environments `export TF_VAR_do_token=<token>`, либо создать файл vars.auto.tfvars и прописать переменную в нем:

```terraform
do_token = "<token>"
```

```shell
$ terraform init
```

Создадим БД Postgres, БД `todo_list`, пользователя `program`. Т.к. Managed Postgres не поддерживает постоянные
коннекты (а в Spring Boot используется Hikari Data Pool), нам надо дополнительно создать Connection Pool.<br>
Проверим, что в манифесте нет ошибок и попробуем создать эти ресурсы:

```shell
$ terraform plan
$ terraform apply
```

Теперь перейдем к самому приложению.

В ресурсе `digitalocean_app` в блоке spec мы фактически повторяем описание
из [DigitalOcean](https://docs.digitalocean.com/products/app-platform/references/app-specification-reference/).

При создании приложения DigitalOcean автоматически создает доменную запись в своем пространстве
имен: `todo-list-app-wx8rr.ondigitalocean.app`. Т.к. мой домен `romanow-alex.ru` зарегистрирован в DigitalOcean, при
описании домена `todo-list.romanow-alex.ru` я указываю `type = "PRIMARY"` и `region = "romanow-alex.ru"` и DigitalOcean
автоматиески создает CNAME c `todo-list.romanow-alex.ru` на `todo-list-app-wx8rr.ondigitalocean.app`.

```shell
$ terraform plan
$ terraform apply
```

## Анонс

Предположим, вы разработчик, сделали какой-то свой небольшой pet-проект и теперь хотите вывести его в prod. Но как это
сделать, из каждого утюга звучит: _Kubernetes_, _Istio_, _Nomad_, _Terraform_ и куча других слов, значение которых
обычному разработчику не понятно. Плюс к этому, каждые полгода появляются новые технологии, которые бесят решают
проблемы, о которых вы даже не слышали. Что делать, с чего начать, чтобы быстро задеплоить ваше приложение?

Рассмотрим **Application Platform** от **DigitalOcean** как средство быстро и просто вывести небольшое приложение в
prod.

_Автор_: Романов Алексей<br>
_Встреча_:  One way ticket to DevOps<br>
_tg_: @romanowalex