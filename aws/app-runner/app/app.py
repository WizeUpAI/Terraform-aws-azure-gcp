
from fastapi import FastAPI, Depends, HTTPException, status, Request
import jwt
from jwt import PyJWKClient
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

COGNITO_REGION = "us-east-1"
USERPOOL_ID = "us-east-1_example"
APP_CLIENT_ID = "your-app-client-id"
COGNITO_ISSUER = f"https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USERPOOL_ID}"
JWKS_URL = f"{COGNITO_ISSUER}/.well-known/jwks.json"

app = FastAPI()
token_auth_scheme = HTTPBearer()
jwks_client = PyJWKClient(JWKS_URL)

def verify_token(token: str):
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    data = jwt.decode(token, signing_key.key, algorithms=["RS256"], audience=APP_CLIENT_ID, issuer=COGNITO_ISSUER)
    return data

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(token_auth_scheme)):
    try:
        return verify_token(credentials.credentials)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@app.get("/secure-data")
def secure_endpoint(user=Depends(get_current_user)):
    return {"message": f"Hello {user['username']}, your token is valid."}
