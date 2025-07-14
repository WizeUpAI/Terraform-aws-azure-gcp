# Utiliser une image officielle Python légère
FROM python:3.10-slim

# Installer les dépendances système (optionnel)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copier requirements (ici minimal, fastapi + uvicorn)
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY ./main.py /app/main.py

WORKDIR /app

# Commande pour lancer FastAPI avec Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
