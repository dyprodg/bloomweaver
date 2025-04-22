# Bloomweaver - Vector Embedding Pipeline - Scrum Plan

## Project Overview
Building a scalable vector embedding pipeline for semantic search using Go, Python, and AWS services.

## Roles
- **Product Owner:** Responsible for defining requirements and prioritizing backlog
- **Scrum Master:** Facilitates the Scrum process and removes impediments
- **Development Team:** Implements the tasks

## Product Backlog (High-Level Epics)
1. **Core Infrastructure Setup** - AWS resources via Terraform
2. **CI/CD Pipeline Setup** - GitHub Actions
3. **Basic Message Flow** - API Gateway → Webhook → SQS
4. **Embedding Worker Implementation** - EC2/Docker/Python
5. **Pinecone Integration** - Vector DB interaction
6. **S3 Backup/Persistence Flow** - JSON backup storage
7. **Authentication & Security Layer** - Clerk/Lambda Authorizer
8. **Frontend Application** - Astro/Clerk/Uploader
9. **Monitoring & Logging Implementation** - CloudWatch
10. **End-to-End Testing & Hardening** - Final polish

## Sprint Plan (2-Week Sprints)

### Sprint 1: Foundation & Core Infrastructure
**Sprint Goal:** Terraform-Basis für Kern-AWS-Ressourcen steht, grundlegende Konnektivität kann getestet werden.

**Tasks:**
- [ ] Terraform Projekt Setup (Provider, Backend State S3/DynamoDB)
- [ ] Terraform Module für:
  - [ ] IAM Roles (Basis-Rollen für Lambdas, EC2)
  - [ ] SQS Queues (Change, Create, Update, Delete, S3, DeadLetterQueues)
  - [ ] Simple API Gateway (ohne Auth erstmal)
  - [ ] S3 Bucket für Backups
- [ ] "Hello World" Lambda Funktion (Go) für Webhook
- [ ] Deployment der Lambda Funktion
- [ ] Verbindung Simple API Gateway → "Hello World" Webhook Lambda

**Definition of Done:** 
- Terraform apply erfolgreich
- SQS Queues existieren
- API Gateway ist erreichbar und triggert die Dummy-Webhook Lambda
- Logs erscheinen in CloudWatch

### Sprint 2: CI/CD Pipelines
**Sprint Goal:** Automatisierte Deployment-Pipelines für alle Komponenten.

**Tasks:**
- [ ] GitHub Actions für Terraform (Infrastructure Deployment)
- [ ] GitHub Actions für Lambdas (Webhook, Create, Update, Delete, S3-Worker, Auth)
- [ ] GitHub Actions für Worker Docker Image
- [ ] GitHub Actions für Frontend

**Definition of Done:**
- Infrastructure wird automatisch nach Terraform-Änderungen deployt
- Lambda-Code wird nach Push/Merge automatisch deployt
- Docker Images werden automatisch gebaut und gepusht
- Frontend wird automatisch nach Push/Merge deployt

### Sprint 3: Webhook Logic & Basic Routing
**Sprint Goal:** Webhook Lambda validiert Requests und leitet sie korrekt an SQS weiter.

**Tasks:**
- [ ] Implementierung der Webhook Lambda Logik (Go):
  - [ ] Request Body Parsing (JSON)
  - [ ] Schema-Validierung (`operation`, `doc_hash`, `content_type`)
  - [ ] `Content-Encoding: gzip` Handling (Dekompression)
  - [ ] Routing: `DELETE` → DeleteQueue, `CREATE/UPDATE` → ChangeQueue
  - [ ] SQS Message Sending implementieren
- [ ] Unit Tests für die Lambda Funktion
- [ ] Deployment der aktualisierten Lambda
- [ ] Testen mit `curl` / Postman (Raw JSON, Gzipped JSON, DELETE vs CREATE)

**Definition of Done:**
- Webhook Lambda validiert korrekte/falsche Requests
- Lambda dekomprimiert Gzip-Inhalte korrekt
- Nachrichten werden an die richtigen SQS Queues weitergeleitet (in CloudWatch SQS Metriken sichtbar)

### Sprint 4: Embedding Worker - Setup & Basic Processing
**Sprint Goal:** Embedding Worker (Python/FastAPI) kann Nachrichten von der ChangeQueue empfangen und (placeholder) verarbeiten. EC2 ASG Infrastruktur steht.

**Tasks:**
- [ ] Terraform Module für:
  - [ ] EC2 Launch Template (mit User Data für Docker Setup)
  - [ ] EC2 Auto Scaling Group (min 0, max N)
  - [ ] ASG Scaling Policies (basierend auf ChangeQueue Tiefe)
  - [ ] IAM Role für EC2 Instanz (SQS Lese-/Schreibzugriff, CloudWatch Logs)
  - [ ] Security Group für EC2
- [ ] Dockerisierung des Python FastAPI Workers:
  - [ ] Dockerfile erstellen
  - [ ] FastAPI App Grundgerüst
  - [ ] SQS Polling Logik (async `boto3`)
  - [ ] Placeholder für Chunking/Embedding (z.B. nur Logging des Inhalts)
  - [ ] Placeholder für Senden an Create/Update Queue
- [ ] Build & Push des Docker Images zu ECR
- [ ] Testen: Nachricht in ChangeQueue → ASG skaliert hoch → Worker empfängt Nachricht → Worker loggt → ASG skaliert runter

**Definition of Done:**
- Terraform apply erfolgreich
- ASG wird erstellt
- Worker Docker Image in ECR
- Worker startet auf EC2, empfängt Nachrichten von ChangeQueue
- ASG skaliert basierend auf Queue-Tiefe

### Sprint 5: Pinecone Integration
**Sprint Goal:** Create/Update/Delete Lambdas können (placeholder) Daten in Pinecone schreiben/löschen.

**Tasks:**
- [ ] Pinecone Account/Index Setup (manuell oder Terraform falls möglich)
- [ ] Terraform für Create/Update/Delete Lambdas (Go)
- [ ] IAM Roles für Lambdas (SQS Trigger, Pinecone Zugriff, CloudWatch Logs)
- [ ] SQS Trigger für Lambdas konfigurieren (CreateQueue → CreateLambda etc.)
- [ ] Implementierung der Lambda Logik (Go):
  - [ ] SQS Event Parsing
  - [ ] Pinecone Client Initialisierung
  - [ ] Pinecone `upsert`/`delete` Operationen (mit Dummy-Vektoren/Metadaten)
  - [ ] Fehlerbehandlung & Logging
- [ ] Unit Tests für Lambdas
- [ ] Deployment der Lambdas
- [ ] Testen: Nachricht in CreateQueue → CreateLambda → Daten in Pinecone sichtbar

**Definition of Done:**
- Lambdas werden von SQS getriggert
- Lambdas interagieren erfolgreich mit Pinecone (Upsert/Delete)
- Fehler werden korrekt geloggt

### Sprint 6: S3 Backup Flow
**Sprint Goal:** JSON-Backups von Dokument-Chunks werden in S3 gespeichert/gelöscht.

**Tasks:**
- [ ] Terraform für S3 Worker Lambda (Go)
- [ ] IAM Role für Lambda (SQS Trigger, S3 Schreib-/Lese-/Löschzugriff, CloudWatch Logs)
- [ ] SQS Trigger für Lambda (S3Queue → S3WorkerLambda)
- [ ] Anpassung Create/Update/Delete Lambdas: Senden Event an S3Queue nach Pinecone Operation
- [ ] Implementierung S3 Worker Lambda Logik (Go):
  - [ ] SQS Event Parsing
  - [ ] S3 Client Initialisierung
  - [ ] `CREATE/UPDATE`: JSON-Datei in S3 speichern (`doc_hash/chunk_id.json`)
  - [ ] `DELETE`: Entsprechende JSON-Dateien aus S3 löschen
- [ ] Unit Tests für S3 Worker Lambda
- [ ] Deployment der Lambdas
- [ ] Testen: Create-Flow → Pinecone + S3 JSON existiert. Delete-Flow → Pinecone + S3 JSON gelöscht

**Definition of Done:**
- Nach Pinecone-Operationen werden entsprechende Events an S3Queue gesendet
- S3 Worker Lambda verarbeitet sie und speichert/löscht JSON-Dateien in S3 korrekt

### Sprint 7: Authentication & Security
**Sprint Goal:** Secure API Gateway mit Clerk Authentifizierung ist funktionsfähig.

**Tasks:**
- [ ] Clerk Setup (Application erstellen)
- [ ] Terraform für Auth Lambda (Go)
- [ ] Terraform für Secure API Gateway (mit Lambda Authorizer)
- [ ] IAM Role für Auth Lambda
- [ ] Implementierung Auth Lambda Logik (Go):
  - [ ] JWT Token Extraktion
  - [ ] Clerk Public Key Fetching/Caching
  - [ ] JWT Verifizierung (mit Clerk Library)
  - [ ] IAM Policy generieren (Allow/Deny)
- [ ] Unit Tests für Auth Lambda
- [ ] Verbindung Secure API Gateway → Auth Lambda → Webhook Lambda
- [ ] Testen mit gültigen/ungültigen Clerk Tokens via Postman

**Definition of Done:**
- Secure API Gateway lehnt Requests ohne/mit ungültigem Token ab
- Gültige Requests werden zur Webhook Lambda durchgelassen

### Sprint 8: Worker - Real Embedding & Chunking
**Sprint Goal:** Embedding Worker implementiert echtes Chunking und Embedding mit `instructor-xl`.

**Tasks:**
- [ ] Anpassung Worker Dockerfile/Setup für ML Model Download/Caching
- [ ] Implementierung der Chunking-Strategie (z.B. Hybrid mit Overlap)
- [ ] Implementierung des Embeddings mit `instructor-xl` (Sentence Transformers / Hugging Face)
- [ ] Anpassung der Worker Logik:
  - [ ] Chunking nach Empfang aus ChangeQueue
  - [ ] Embedding für jeden Chunk
  - [ ] Senden der Chunks (mit Vektoren) an Create/Update Queue
- [ ] Performance-Optimierung / Batching für Embedding
- [ ] Testen mit echten Textdokumenten

**Definition of Done:**
- Worker chunkt Text korrekt
- Worker generiert Vektor-Embeddings
- Worker sendet strukturierte Chunk-Daten an die Pinecone Queues

### Sprint 9: Frontend Basics
**Sprint Goal:** Grundlegende Frontend-Funktionalität mit Astro und Clerk.

**Tasks:**
- [ ] Astro Projekt Setup
- [ ] Clerk Integration (Auth UI)
- [ ] Einfache Seite zum Senden von Text an Secure API Gateway
- [ ] Deployment auf S3/CloudFront

**Definition of Done:**
- Frontend kann Texteingaben an API senden
- Authentifizierung via Clerk funktioniert

### Sprint 10: Frontend Features
**Sprint Goal:** Erweiterte Frontend-Funktionen für Dokumentenverwaltung.

**Tasks:**
- [ ] File Uploader mit Client-seitiger Extraktion/Vorbereitung
- [ ] Einfacher DB-Editor (liest ggf. aus S3)
- [ ] Suchfunktion implementieren

**Definition of Done:**
- Benutzer können Dateien hochladen
- Benutzer können Dokumente verwalten
- Benutzer können in indexierten Dokumenten suchen

### Sprint 11: Monitoring & Testing
**Sprint Goal:** Umfassendes Monitoring und End-to-End Tests.

**Tasks:**
- [ ] CloudWatch Alarms (Queue Depth, Lambda Errors, EC2 CPU)
- [ ] CloudWatch Dashboards
- [ ] End-to-End Tests (Upload → Search)
- [ ] Load Testing

**Definition of Done:**
- Alarme werden bei Problemen ausgelöst
- Dashboards zeigen System-Health
- End-to-End Tests validieren den kompletten Flow

### Sprint 12: Hardening & Documentation
**Sprint Goal:** Finalisierung und Dokumentation des Systems.

**Tasks:**
- [ ] Security Review
- [ ] Code Cleanup
- [ ] Performance Tuning
- [ ] README aktualisieren
- [ ] Operational Runbook erstellen

**Definition of Done:**
- System ist sicher und performant
- Dokumentation ist vollständig
- Code ist aufgeräumt und wartbar

## Daily Scrum
Kurzes tägliches Check-in zu:
- Was wurde seit gestern erledigt?
- Was ist für heute geplant?
- Gibt es Hindernisse?

## Sprint Review
Am Ende jedes Sprints:
- Präsentation der fertigen Inkremente
- Feedback sammeln
- Backlog anpassen

## Sprint Retrospektive
Nach jedem Sprint:
- Was lief gut?
- Was könnte verbessert werden?
- Aktionen für den nächsten Sprint festlegen

## Definition of Ready
Ein Backlog-Item ist "ready", wenn:
- Es klar beschrieben ist
- Der Umfang bekannt ist
- Akzeptanzkriterien definiert sind
- Das Team es verstanden hat

## Definition of Done
Ein Item ist "done", wenn:
- Code geschrieben und getestet ist
- Code Reviews durchgeführt wurden
- Dokumentation aktualisiert wurde
- Akzeptanzkriterien erfüllt sind
- Es deployed wurde und funktioniert
