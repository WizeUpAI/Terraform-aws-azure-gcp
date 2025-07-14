Voici la liste principale des bases de données disponibles sur Google Cloud Platform (GCP), accompagnée de leur cas d’usage principal et d’un exemple Terraform pour chacune.

✅ Bases de données sur GCP
```
Type	                Nom du service GCP	                        Cas d’usage principal
SQL managé	            Cloud SQL (MySQL/PostgreSQL/SQL Server)	    Apps web, SaaS, applications classiques
NoSQL document	        Firestore / Datastore	                    Applications temps réel, mobiles, microservices
NoSQL clé-valeur	    Memorystore (Redis/Memcached)	            Cache, sessions
NoSQL scalable	        Bigtable	                                Analytics temps réel, IoT, séries temporelles
Multi-modèle	        Firebase Realtime Database	                Mobile/web apps en temps réel (Firebase)
Colonne massive	        BigQuery	                                Data warehouse, requêtes SQL massives
Graph	                (Via partenaires comme Neo4j sur GCE)	    Requêtes graphe
Relationnel libre	    AlloyDB (PostgreSQL avancé)	                PostgreSQL + performance + IA intégrée
Relationnel natif	    Spanner	                                    Scalabilité horizontale + SQL + transactions
```

📦 Terraform Code par Base
1️⃣ Cloud SQL (MySQL/PostgreSQL/SQL Server)
```
resource "google_sql_database_instance" "db" {
  name             = "my-sql-instance"
  region           = "us-central1"
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_user" "user" {
  name     = "dbuser"
  instance = google_sql_database_instance.db.name
  password = "MySecret123!"
}

resource "google_sql_database" "database" {
  name     = "mydb"
  instance = google_sql_database_instance.db.name
}
```

2️⃣ Firestore (Native Mode)
```
resource "google_firestore_database" "default" {
  name     = "(default)"
  project  = var.project_id
  location_id = "nam5" # us-central is `nam5`
  type     = "NATIVE"
}
```

3️⃣ Memorystore (Redis)
```
resource "google_redis_instance" "redis" {
  name              = "redis-instance"
  tier              = "BASIC"
  memory_size_gb    = 1
  region            = "us-central1"
  authorized_network = "default" # ou nom de ton VPC
}
```

4️⃣ Bigtable
```
resource "google_bigtable_instance" "bt" {
  name          = "bt-instance"
  cluster {
    cluster_id   = "bt-cluster"
    zone         = "us-central1-b"
    num_nodes    = 1
    storage_type = "SSD"
  }
  instance_type = "PRODUCTION"
}
```

5️⃣ Firebase Realtime Database
```
Firebase RTDB n’a pas de ressource Terraform officielle GCP native. Tu dois passer par gcloud ou la console Firebase. Possible via google_firebase_project + API.
```

6️⃣ BigQuery (dataset)
```
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "my_dataset"
  location   = "US"
}
```

7️⃣ AlloyDB
```
resource "google_alloydb_instance" "alloydb" {
  instance_id     = "my-alloydb"
  cluster         = google_alloydb_cluster.cluster.id
  instance_type   = "PRIMARY"
}

resource "google_alloydb_cluster" "cluster" {
  cluster_id = "my-cluster"
  location   = "us-central1"

  network = "projects/${var.project_id}/global/networks/default"

  initial_user {
    password = "AlloyStrongPass!"
  }
}
```

8️⃣ Cloud Spanner
```
resource "google_spanner_instance" "spanner" {
  name         = "spanner-instance"
  config       = "regional-us-central1"
  display_name = "Spanner Instance"
  num_nodes    = 1
}

resource "google_spanner_database" "db" {
  name            = "spanner-db"
  instance        = google_spanner_instance.spanner.name
  database_dialect = "GOOGLE_STANDARD_SQL"
  ddl = [
    "CREATE TABLE users ( id STRING(36) NOT NULL, name STRING(100) ) PRIMARY KEY(id)"
  ]
}
```

🧠 Recommandations
🔐 Sépare les identifiants (passwords) dans un fichier terraform.tfvars ou dans Secret Manager.
🛡️ Utilise le champ authorized_networks pour limiter l'accès à Cloud SQL.
🔁 Utilise des modules pour réutiliser ta config sur plusieurs projets ou environnements.