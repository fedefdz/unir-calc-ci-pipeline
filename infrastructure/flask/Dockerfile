FROM python:3.11-slim

WORKDIR /workspace

RUN pip install --no-cache-dir flask==3.0.3

ENV PYTHONPATH=/workspace \
    FLASK_APP=app.api:api_application

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
