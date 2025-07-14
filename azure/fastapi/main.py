from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.security import OAuth2AuthorizationCodeBearer
from starlette.middleware.authentication import AuthenticationMiddleware
from jose import jwt
import httpx
import os

app = FastAPI()

TENANT_ID = os.getenv("AZURE_TENANT_ID")
CLIENT_ID = os.getenv("AZURE_CLIENT_ID")
ISSUER = f"https://login.microsoftonline.com/{TENANT_ID}/v2.0"
JWKS_URI = f"{ISSUER}/discovery/v2.0/keys"
AUDIENCE = CLIENT_ID

oauth2_scheme = OAuth2AuthorizationCodeBearer(
    authorizationUrl=f"{ISSUER}/oauth2/v2.0/authorize",
    tokenUrl=f"{ISSUER}/oauth2/v2.0/token"
)

# Récupération des clés publiques de Microsoft pour vérifier le token
async def get_jwk_keys():
    async with httpx.AsyncClient() as client:
        resp = await client.get(JWKS_URI)
        return resp.json()["keys"]

async def decode_token(token: str):
    keys = await get_jwk_keys()
    for key in keys:
        try:
            return jwt.decode(token, key, algorithms=["RS256"], audience=AUDIENCE, issuer=ISSUER)
        except jwt.JWTError:
            continue
    raise HTTPException(status_code=401, detail="Invalid token")

@app.get("/")
async def protected(token: str = Depends(oauth2_scheme)):
    payload = await decode_token(token)
    email = payload.get("preferred_username")
    roles = payload.get("roles", [])

    if not email:
        raise HTTPException(status_code=403, detail="Email not found in token")

    # Vérifie que l'utilisateur a le rôle attendu
    if "MyApp.User" not in roles:
        raise HTTPException(status_code=403, detail=f"User {email} not authorized")

    return {"message": f"Welcome {email}!", "roles": roles}
