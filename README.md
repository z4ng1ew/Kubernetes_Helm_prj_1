# README.md

```markdown
# Secure Bookstore

Проект «Secure Bookstore» — это многосервисное приложение, реализованное с использованием современных технологий контейнеризации, оркестрации и DevSecOps-практик.  
Цель проекта — не просто развернуть приложение в Kubernetes, а сделать это с использованием лучших практик безопасности и автоматизации.

---

## Описание проекта

Secure Bookstore — онлайн-магазин книг, состоящий из трёх сервисов:

- **Frontend:** React-приложение на Node.js (JavaScript)  
- **Backend:** REST API на Python с использованием Flask  
- **База данных:** PostgreSQL с постоянным хранилищем (PersistentVolumeClaim)

---

## Стек технологий и инструменты

- **Контейнеризация:** Docker (Dockerfile для frontend и backend)  
- **Оркестрация:** Kubernetes  
- **Менеджер пакетов для Kubernetes:** Helm (разработка собственного Helm-чарта)  
- **Безопасность контейнеров:** Trivy (сканирование образов на уязвимости)  
- **Проверки состояния контейнеров:** readinessProbe и livenessProbe  
- **Сетевая политика:** NetworkPolicy Kubernetes для ограничения трафика между сервисами  
- **TLS:** TLS-сертификаты для защищённого HTTPS (через kubectl secrets)  
- **CI/CD:** GitLab CI, автоматизация сборки, сканирования и деплоя  
- **Языки:** JavaScript (React, Node.js), Python (Flask)  
- **База данных:** PostgreSQL

---

## Особенности реализации

- Разделение на frontend, backend и БД с отдельными деплойментами и сервисами.  
- Helm-чарт с параметризованными значениями (values.yaml) для настройки репозиториев образов, ресурсов и количества реплик.  
- Использование PersistentVolumeClaim для хранения данных PostgreSQL.  
- Включение readiness и liveness проб для повышения надёжности приложения.  
- Защищённый доступ через Ingress с TLS.  
- Ограничение сетевого трафика с помощью NetworkPolicy для минимизации поверхности атаки.  
- Автоматический CI/CD пайплайн с использованием GitLab CI и сканированием образов через Trivy.  

---

## Структура проекта



secure-bookstore/
├── charts/                   # Helm-чарты для приложения
│   └── bookstore/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment-frontend.yaml
│           ├── service-frontend.yaml
│           ├── ingress.yaml
│           ├── deployment-backend.yaml
│           ├── service-backend.yaml
│           ├── pvc.yaml
│           └── secrets.yaml
├── ci/                       # GitLab CI пайплайн и скрипты
│   ├── .gitlab-ci.yml
│   └── trivy-scan.sh
├── frontend/                 # Исходники frontend (React + Node.js)
│   ├── Dockerfile
│   └── src/
└── backend/                  # Исходники backend (Python Flask)
├── Dockerfile
└── app.py


---

## Навыки и компетенции, прокачиваемые в проекте

- Проектирование и развёртывание многосервисных приложений в Kubernetes.  
- Создание и настройка Helm-чартов для удобного управления приложениями.  
- Настройка readiness/liveness проб для повышения стабильности.  
- Внедрение сетевых политик Kubernetes для ограничения межсервисного трафика.  
- Организация TLS-шифрования и секретов Kubernetes для безопасности передачи данных.  
- Проведение сканирования контейнерных образов на уязвимости с помощью Trivy (DevSecOps).  
- Автоматизация CI/CD с GitLab для сборки, тестирования и деплоя.  
- Работа с Docker, React, Flask и PostgreSQL — полный стек современных веб-технологий.

---

## Краткое описание 

### Русский:

Многосервисное приложение Secure Bookstore: frontend на React, backend на Flask и БД PostgreSQL, запущенное в Kubernetes через Helm. Внедрены readiness/liveness-пробы, NetworkPolicy, TLS и сканирование образов Trivy. Демонстрация навыков DevSecOps и безопасного деплоя.

### English:

Secure Bookstore is a microservices app with React frontend, Flask backend, and PostgreSQL DB deployed via Helm on Kubernetes. Features readiness/liveness probes, NetworkPolicy, TLS, and Trivy image scanning. Showcases DevSecOps skills and secure deployment practices.

