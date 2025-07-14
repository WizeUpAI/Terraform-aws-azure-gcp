🔐 Étapes à suivre sur Azure
1. Créer une App Registration Azure AD
Va sur Azure Active Directory → App registrations → New registration

Redirect URI: http://localhost:8000/docs

Copie :

AZURE_TENANT_ID
AZURE_CLIENT_ID

2. Créer des rôles d’application (optionnel)
json
Copy
Edit
"appRoles": [
  {
    "allowedMemberTypes": [ "User" ],
    "description": "User role for the API",
    "displayName": "MyApp.User",
    "id": "...",
    "isEnabled": true,
    "value": "MyApp.User"
  }
]
Puis assigne ce rôle à tes utilisateurs dans "Enterprise applications" → "Users and groups".

🛠 Variables d’environnement à configurer dans Azure
bash
Copy
Edit
AZURE_TENANT_ID = <ton-tenant-id>
AZURE_CLIENT_ID = <client-id de l'app FastAPI>
🧪 Test d’authentification
Accède à /docs

Clique sur "Authorize"

Authentifie-toi avec ton compte Azure AD

Le token est vérifié et l’email est utilisé dans /

