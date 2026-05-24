FROM python:3.13.3-bookworm

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

RUN pip install --upgrade pip wheel "poetry==2.1.3"

RUN poetry config virtualenvs.create false --local

COPY pyproject.toml poetry.lock ./

RUN poetry install

COPY fastapi-application .

RUN chmod +x prestart.sh

ENTRYPOINT ["./prestart.sh"]

CMD ["python", "./main.py"]