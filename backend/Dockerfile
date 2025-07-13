# Dockerfile для бэкенда
# Используем официальный Python образ
FROM python:3.11-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файл зависимостей
COPY requirements.txt .

# Обновляем pip и устанавливаем зависимости
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Копируем исходный код приложения
COPY . .

# Создаем пользователя для безопасности (опционально)
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Открываем порт для приложения
EXPOSE 8000

# Команда для запуска приложения
# Замените на вашу команду запуска (например, для Django, Flask, FastAPI)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Альтернативные команды для разных фреймворков:
# Для Flask: CMD ["python", "app.py"]
# Для FastAPI: CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# Для Django: CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
