
# FastAPI + Cognito + AWS App Runner (via Terraform)

## 🔐 Authentification
- Utilise Amazon Cognito pour sécuriser l'API avec JWT.
- Le token est validé dans FastAPI via PyJWT et les JWKS.

## 🚀 Déploiement CI/CD (GitHub Actions)
- Construction Docker → Push vers ECR
- Déploiement App Runner + Cognito via Terraform

## 🧪 Tester l'API
```bash
curl -H "Authorization: Bearer <TOKEN>" https://your-app-url/secure-data
```

## 📂 Structure
- `app/` : Code Python + Dockerfile
- `infra/` : Fichiers Terraform
- `.github/` : CI/CD
