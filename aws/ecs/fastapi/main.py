from fastapi import FastAPI, Request, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
import os
import requests

app = FastAPI()

security = HTTPBearer()

COGNITO_REGION = os.getenv("COGNITO_REGION", "us-east-1")
USER_POOL_ID = os.getenv("COGNITO_USER_POOL_ID")
AUDIENCE = os.getenv("COGNITO_CLIENT_ID")
ISSUER = f"https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USER_POOL_ID}"

# Load JWKS from Cognito
def get_cognito_jwks():
    url = f"{ISSUER}/.well-known/jwks.json"
    return requests.get(url).json()

JWKS = get_cognito_jwks()

def verify_token(token: str):
    for key in JWKS["keys"]:
        try:
            payload = jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                audience=AUDIENCE,
                issuer=ISSUER
            )
            return payload
        except JWTError:
            continue
    raise HTTPException(status_code=401, detail="Invalid token")

async def authenticate_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    payload = verify_token(token)
    return payload

@app.get("/")
def welcome(user=Depends(authenticate_user)):
    return {
        "message": f"Welcome {user['email']}",
        "cognito_sub": user["sub"],
        "groups": user.get("cognito:groups", [])
    }
