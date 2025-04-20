# BloomWeaver - KI Wissensdatenbank Plattform

## 🌐 Projektbeschreibung

BloomWeaver ist eine hochskalierbare, serverlose Plattform zur Verwaltung von Wissensdatenbanken mit KI-Unterstützung. Dokumente und Inhalte werden verarbeitet, vektorisiert und in Pinecone gespeichert, um schnelle semantische Suchen und KI-gestützte Antworten zu ermöglichen.

Dieses Projekt wird als Solo-Projekt von Dennis Diepolder entwickelt.

---

# 📊 Systemarchitektur

### Frontend

- **Astro** Framework für statische Seiten.
- **Clerk** für User Authentication.
- **Hosting** über **AWS S3** + **CloudFront**.
- **Domain Management** über **Route53**.
- **SSL** über **ACM Zertifikate**.
- **Uploader und Dateieditor** im Admin Dashboard, der Dateien verarbeitet und automatisch an die Webhook übermittelt.
- **Datenbank-Editor** im Admin Dashboard, der gehashte Einträge automatisch an die Webhook sendet.

### Backend

- **Sprache:** Alles in **Go**, außer dem Embedding Worker, der in **Python** entwickelt ist.
- **API Gateway** für Webhook Empfang.
- **Webhook Lambda**:
  - Löschen (DELETE) direkt
  - Erstellen/Updaten (INSERT/UPDATE) über SQS Queuing
- **SQS Queues**:
  - ChangeQueue
  - CreateQueue
  - UpdateQueue
  - DeadLetterQueue (für Fehlerbehandlung)
- **Embedding Worker** (FastAPI Python Service):
  - Modell: `BAAI/bge-small-en-v1.5`
  - Deployment über ECS Fargate oder EC2
- **Create Lambda / Update Lambda**:
  - Schreiben der Embeddings in Pinecone
- **Pinecone** als Vektordatenbank
- **Optional**: RDS PostgreSQL für Rohdaten + S3 für Dateiuploads

### Infrastruktur

- Komplett via **Terraform** gebaut.
- CI/CD Pipelines mit **GitHub Actions**:
  - Lambdas (webhook, create, update)
  - Embedding Worker (Docker Build + ECR Push)
  - Astro Frontend (S3 Sync + CloudFront Invalidate)
- Deployment getriggert per `paths` in GitHub Actions (nur bei Änderungen)

### Monitoring & Logging

- **CloudWatch Logs** für alle Lambdas und ECS Services.
- LogGroup Management über Terraform.
- Fehlerhafte Nachrichten über **DeadLetterQueues**.

---

# 🔢 Projektstruktur

```plaintext
/bloomweaver
├── terraform/
│   ├── api_gateway/
│   ├── lambdas/
│   │   ├── webhook/
│   │   ├── create/
│   │   ├── update/
│   ├── sqs/
│   │   ├── change-queue/
│   │   ├── create-queue/
│   │   ├── update-queue/
│   │   ├── deadletter-queue/
│   ├── ecs/
│   │   ├── embedding-worker/
│   ├── s3_frontend/
│   ├── cloudfront/
│   ├── rds/
├── lambdas/
│   ├── webhook/
│   ├── create/
│   ├── update/
├── embedding-worker/
│   ├── Dockerfile
│   ├── app/
├── frontend/
│   ├── public/
│   ├── src/
├── .github/
│   ├── workflows/
│   │   ├── lambda-webhook.yml
│   │   ├── lambda-create.yml
│   │   ├── lambda-update.yml
│   │   ├── embedding-worker.yml
│   │   ├── frontend-deploy.yml
│   │   ├── terraform-apply.yml
```

---

# 📕 Infrastruktur-Komponenten

## API Gateway + Webhook Lambda

- Validiert Webhook Calls.
- Delegiert je nach `change_type` (insert/update/delete).

## SQS Queues

- Entkoppeln die Verarbeitungsschritte.
- Retry Management durch DeadLetterQueues.

## Embedding Worker

- Splitten von Dokumenten.
- Embedding Generierung über Huggingface Transformers.
- Bereitstellung als REST API.

## Create/Update Lambdas

- Schreiben/Updaten der Embeddings in Pinecone.
- Einhaltung der Konsistenz durch Doc-Hash Matching.

## Pinecone

- Speicherung der Vektor-Repräsentationen.

## RDS + S3 (optional)

- Speicherung von Rohdaten oder originalen Dateien für spätere Referenzierungen.

---

# 🚀 CI/CD Flows

- Webhook Lambda Build/Deploy
- Create Lambda Build/Deploy
- Update Lambda Build/Deploy
- Embedding Worker Docker Build + Push zu ECR
- Frontend Astro Build + Sync zu S3
- Terraform Apply nur bei Änderung an Infrastruktur-Code

---

# 📈 Observability (Phase 1)

- CloudWatch Loggroups pro Service
- Fehlerauswertung über DeadLetter Queues

---

# 🚀 Deployment Prozess (First Boot)

1. Terraform Infrastruktur aufbauen (terraform apply).
2. Webhook, Create und Update Lambdas bauen und hochladen.
3. Embedding Worker bauen, nach ECR pushen und Service deployen.
4. Astro Frontend bauen und auf S3 synchronisieren.
5. CloudFront Distribution invalidieren.
6. Clerk einrichten für Frontend-Authentication.
7. API Gateway Endpoint an Client übergeben.

---

# 🔒 Security Best Practices

- IAM Rollen mit least-privilege.
- SQS Queues private.
- Pinecone API Keys sicher verwalten.
- Clerk für sichere Authentifizierung der User.
- SSL überall aktiv.

---

# 🚀 Erweiterungspläne

- Lokale Embedding Worker auf GPU Nodes.
- Multimodale Modelle (Text + Bilder).
- Admin Dashboard über Grafana Cloud.
- Automatische Chunk Optimierungen bei Dokumenten-Importen.
- API Gateway Rate Limits pro Kunde.
- Direkter Datenbank-Editor über das Admin Dashboard.
- Upload- und Datei-Editor direkt zum Projektstart.

---

# 👋 Kontakt

Projektleitung: Dennis Diepolder
Technische Leitung: Dennis Diepolder
Lizenz: Privat / Company Internal

---

> **Hinweis:** Dieses Projekt ist modular aufgebaut und kann jederzeit mit minimalem Aufwand um Logging, Monitoring, neue Features und neue Kundenquellen erweitert werden.

