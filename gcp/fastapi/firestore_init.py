from google.cloud import firestore

db = firestore.Client()
users_ref = db.collection("users")

users_ref.document("john.doe@gmail.com").set({
    "role": "admin",
    "active": True
})
users_ref.document("viewer@tondomaine.com").set({
    "role": "viewer",
    "active": True
})
