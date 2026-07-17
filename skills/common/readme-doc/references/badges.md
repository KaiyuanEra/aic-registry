# 徽章参考库

shields.io 徽章格式：`https://img.shields.io/badge/<label>-<message>-<color>?style=flat&logo=<logo-slug>`

logo slug 来自 [Simple Icons](https://simpleicons.org/)，搜索技术名即可获取准确 slug。

## 语言 / 运行时

```markdown
[![Go](https://img.shields.io/badge/Go-1.24+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=flat&logo=nodedotjs)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python)](https://python.org/)
[![Rust](https://img.shields.io/badge/Rust-1.75+-000000?style=flat&logo=rust)](https://rust-lang.org/)
[![Java](https://img.shields.io/badge/Java-21+-ED8B00?style=flat&logo=openjdk)](https://openjdk.org/)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-7F52FF?style=flat&logo=kotlin)](https://kotlinlang.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=flat&logo=typescript)](https://typescriptlang.org/)
[![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?style=flat&logo=php)](https://php.net/)
[![Ruby](https://img.shields.io/badge/Ruby-3.x-CC342D?style=flat&logo=ruby)](https://ruby-lang.org/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift)](https://swift.org/)
```

## 数据库

```markdown
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=flat&logo=postgresql)](https://postgresql.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql)](https://mysql.com/)
[![SQLite](https://img.shields.io/badge/SQLite-3.x-003B57?style=flat&logo=sqlite)](https://sqlite.org/)
[![Redis](https://img.shields.io/badge/Redis-7.x-DC382D?style=flat&logo=redis)](https://redis.io/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?style=flat&logo=mongodb)](https://mongodb.com/)
[![ClickHouse](https://img.shields.io/badge/ClickHouse-23.x-FFCC01?style=flat&logo=clickhouse)](https://clickhouse.com/)
[![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.x-005571?style=flat&logo=elasticsearch)](https://elastic.co/)
[![Cassandra](https://img.shields.io/badge/Cassandra-4.x-1287B1?style=flat&logo=apachecassandra)](https://cassandra.apache.org/)
```

## Web 框架

```markdown
[![Gin](https://img.shields.io/badge/Gin-1.x-00ADD8?style=flat&logo=go)](https://gin-gonic.com/)
[![Echo](https://img.shields.io/badge/Echo-4.x-00ADD8?style=flat&logo=go)](https://echo.labstack.com/)
[![Fiber](https://img.shields.io/badge/Fiber-2.x-00ADD8?style=flat&logo=go)](https://gofiber.io/)
[![React](https://img.shields.io/badge/React-18+-61DAFB?style=flat&logo=react)](https://react.dev/)
[![Vue](https://img.shields.io/badge/Vue-3.x-4FC08D?style=flat&logo=vuedotjs)](https://vuejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-14+-000000?style=flat&logo=nextdotjs)](https://nextjs.org/)
[![Nuxt](https://img.shields.io/badge/Nuxt-3.x-00DC82?style=flat&logo=nuxtdotjs)](https://nuxt.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Django](https://img.shields.io/badge/Django-4.x-092E20?style=flat&logo=django)](https://djangoproject.com/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-6DB33F?style=flat&logo=springboot)](https://spring.io/projects/spring-boot/)
[![Laravel](https://img.shields.io/badge/Laravel-10.x-FF2D20?style=flat&logo=laravel)](https://laravel.com/)
```

## 消息队列 / 流处理

```markdown
[![Kafka](https://img.shields.io/badge/Kafka-3.x-231F20?style=flat&logo=apachekafka)](https://kafka.apache.org/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-3.x-FF6600?style=flat&logo=rabbitmq)](https://rabbitmq.com/)
[![NATS](https://img.shields.io/badge/NATS-2.x-27AAE1?style=flat&logo=natsdotio)](https://nats.io/)
```

## 基础设施 / DevOps

```markdown
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat&logo=docker)](https://docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-326CE5?style=flat&logo=kubernetes)](https://kubernetes.io/)
[![GitLab CI](https://img.shields.io/badge/GitLab_CI-passing-FC6D26?style=flat&logo=gitlab)](https://gitlab.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-passing-2088FF?style=flat&logo=githubactions)](https://github.com/features/actions)
[![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?style=flat&logo=terraform)](https://terraform.io/)
[![Helm](https://img.shields.io/badge/Helm-3.x-0F1689?style=flat&logo=helm)](https://helm.sh/)
```

## 许可证

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![License: Private](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)
```

## 自定义徽章

当项目使用的技术在上方找不到时，用以下公式构造：

```
https://img.shields.io/badge/<显示文字>-<版本>-<品牌色>?style=flat&logo=<simpleicons-slug>
```

1. 在 https://simpleicons.org/ 搜索技术名，获取 slug 和品牌色（hex）
2. 将 hex 颜色去掉 `#` 填入 `<color>` 位置
3. logo slug 中空格用连字符替代（如 `Apache Kafka` → `apachekafka`）
