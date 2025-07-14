from fastapi import FastAPI, Request, HTTPException
from google.cloud import firestore
import os

app = FastAPI()

# Initialisation Firestore
db = firestore.Client()
COLLECTION = os.getenv("FIRESTORE_COLLECTION", "users")

@app.middleware("http")
async def iap_auth_middleware(request: Request, call_next):
    iap_header = request.headers.get("x-goog-authenticated-user-email")
    if not iap_header:
        raise HTTPException(status_code=401, detail="Unauthorized: missing IAP header")

    try:
        email = iap_header.split(":")[1]
    except IndexError:
        raise HTTPException(status_code=401, detail="Malformed IAP header")

    user_doc = db.collection(COLLECTION).document(email).get()
    if not user_doc.exists or not user_doc.to_dict().get("active", False):
        raise HTTPException(status_code=403, detail=f"Access denied for user {email}")

    # Ajoute l’utilisateur à l’état de la requête
    request.state.user_email = email
    request.state.user_data = user_doc.to_dict()

    return await call_next(request)

@app.get("/")
async def welcome(request: Request):
    return {
        "message": f"Bienvenue {request.state.user_email} !",
        "role": request.state.user_data.get("role", "user")
    }
