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
4. **Document Status Tracking** - DynamoDB for document state management
5. **Go Embedding Worker** - Batch processing & chunking
6. **Python Embedding API** - FastAPI for vector computation
7. **Pinecone Integration** - Vector DB interaction
8. **S3 Backup/Persistence Flow** - JSON backup storage
9. **Authentication & Security Layer** - Clerk/Lambda Authorizer
10. **Frontend Application** - Astro/Clerk/Uploader
11. **Monitoring & Logging Implementation** - CloudWatch
12. **End-to-End Testing & Hardening** - Final polish

## Sprint Plan (2-Week Sprints)

### Sprint 1: Foundation & Core Infrastructure
**Sprint Goal:** Terraform-Basis für Kern-AWS-Ressourcen steht, grundlegende Konnektivität kann getestet werden.

**Tasks:**
- [x] Terraform Projekt Setup (Provider, Backend State S3/DynamoDB)
- [ ] Terraform Module für:
  - [ ] IAM Roles (Basis-Rollen für Lambdas, EC2)
  - [ ] SQS Queues (Change, Create, Update, Delete, S3, DeadLetterQueues)
  - [ ] Simple API Gateway (ohne Auth erstmal)
  - [ ] S3 Bucket für Backups
  - [ ] DynamoDB für Dokument-Status Tracking
  - [ ] EC2 Spot-Instances für Go Worker und Python API
- [ ] "Hello World" Lambda Funktion (Go) für Webhook
- [ ] Deployment der Lambda Funktion
- [ ] Verbindung Simple API Gateway → "Hello World" Webhook Lambda

**Definition of Done:** 
- Terraform apply erfolgreich
- SQS Queues existieren
- DynamoDB Table für Dokument-Status existiert
- API Gateway ist erreichbar und triggert die Dummy-Webhook Lambda
- Logs erscheinen in CloudWatch

### Sprint 2: CI/CD Pipelines
**Sprint Goal:** Automatisierte Deployment-Pipelines für alle Komponenten.

**Tasks:**
- [ ] GitHub Actions für Terraform (Infrastructure Deployment)
- [ ] GitHub Actions für Lambdas (Webhook, Create, Update, Delete, S3-Worker, Auth)
- [ ] GitHub Actions für Go Worker Docker Image
- [ ] GitHub Actions für Python API Docker Image
- [ ] GitHub Actions für Frontend

**Definition of Done:**
- Infrastructure wird automatisch nach Terraform-Änderungen deployt
- Lambda-Code wird nach Push/Merge automatisch deployt
- Docker Images werden automatisch gebaut und gepusht
- Frontend wird automatisch nach Push/Merge deployt

### Sprint 3: Webhook Logic & Document Status Tracking
**Sprint Goal:** Webhook Lambda validiert Requests, aktualisiert DynamoDB und leitet sie korrekt an SQS weiter.

**Tasks:**
- [ ] Implementierung der Webhook Lambda Logik (Go):
  - [ ] Request Body Parsing (JSON)
  - [ ] Schema-Validierung (`operation`, `doc_hash`, `content_type`)
  - [ ] `Content-Encoding: gzip` Handling (Dekompression)
  - [ ] Dokument-Status in DynamoDB speichern (doc_id, status, timestamp)
  - [ ] Routing: `DELETE` → DeleteQueue, `CREATE/UPDATE` → ChangeQueue
  - [ ] SQS Message Sending implementieren
- [ ] Unit Tests für die Lambda Funktion
- [ ] Deployment der aktualisierten Lambda
- [ ] Testen mit `curl` / Postman (Raw JSON, Gzipped JSON, DELETE vs CREATE)

**Definition of Done:**
- Webhook Lambda validiert korrekte/falsche Requests
- Lambda dekomprimiert Gzip-Inhalte korrekt
- Dokument-Status wird in DynamoDB gespeichert
- Nachrichten werden an die richtigen SQS Queues weitergeleitet (in CloudWatch SQS Metriken sichtbar)

### Sprint 4: Go Embedding Worker - Setup & Basic Processing
**Sprint Goal:** Go Embedding Worker kann Nachrichten aus der ChangeQueue in Batches verarbeiten und Chunking durchführen.

**Tasks:**
- [ ] Terraform Module für EC2 Spot-Instances (Go Worker)
- [ ] Implementierung des Go Workers:
  - [ ] SQS Batch Message Processing
  - [ ] DynamoDB Status-Check vor der Verarbeitung
  - [ ] Chunking-Implementierung
  - [ ] Multi-Threading/Goroutines für parallele Verarbeitung
  - [ ] Großzügige SQS Visibility Timeout Handling
  - [ ] Dockerfile für den Go Worker
- [ ] IAM Role für EC2 Spot-Instance (SQS/DynamoDB/S3 Zugriff)
- [ ] Build & Push des Docker Images zu ECR
- [ ] Scripts für manuelles Starten/Scheduling des Workers

**Definition of Done:**
- Go Worker kann erfolgreich auf Spot-Instances laufen
- Worker kann Batches aus der ChangeQueue verarbeiten
- Worker prüft DynamoDB-Status vor Verarbeitung
- Worker führt Chunking durch
- Worker kann fehlerfrei beendet werden, Messages kehren zur Queue zurück

### Sprint 5: Python Embedding API - Setup & Integration
**Sprint Goal:** Python FastAPI Service zur Berechnung von Embeddings ist implementiert und kann vom Go Worker angesprochen werden.

**Tasks:**
- [ ] Terraform Module für EC2 Spot-Instances (Python API)
- [ ] Implementierung der Python FastAPI:
  - [ ] Endpunkte für das Embedding
  - [ ] Model Loading (`instructor-xl`)
  - [ ] Integration mit dem Go Worker
  - [ ] Dockerfile für die Python API
- [ ] IAM Role für die EC2 Spot-Instance
- [ ] Build & Push des Docker Images zu ECR
- [ ] Integration in den Go Worker:
  - [ ] HTTP Client für API-Calls
  - [ ] Fehlerbehandlung & Retry-Logik
  - [ ] Parallelisierung der API-Anfragen

**Definition of Done:**
- Python API kann erfolgreich auf Spot-Instances laufen
- Go Worker kann die Python API ansprechen
- API liefert korrekte Embeddings zurück
- System handhabt Fehler und Retries korrekt

### Sprint 6: Pinecone Integration
**Sprint Goal:** Create/Update/Delete Lambdas können Daten in Pinecone schreiben/löschen.

**Tasks:**
- [ ] Pinecone Account/Index Setup (manuell oder Terraform falls möglich)
- [ ] Terraform für Create/Update/Delete Lambdas (Go)
- [ ] IAM Roles für Lambdas (SQS Trigger, Pinecone Zugriff, CloudWatch Logs)
- [ ] SQS Trigger für Lambdas konfigurieren (CreateQueue → CreateLambda etc.)
- [ ] Implementierung der Lambda Logik (Go):
  - [ ] SQS Event Parsing
  - [ ] Pinecone Client Initialisierung
  - [ ] Pinecone `upsert`/`delete` Operationen
  - [ ] Fehlerbehandlung & Logging
- [ ] Anpassung Go Worker: Senden von Batch-Messages an Create/Update Queues
- [ ] Unit Tests für Lambdas
- [ ] Deployment der Lambdas
- [ ] E2E-Test: Go Worker → Python API → CreateQueue → CreateLambda → Pinecone

**Definition of Done:**
- Lambdas werden von SQS getriggert
- Lambdas interagieren erfolgreich mit Pinecone (Upsert/Delete)
- Go Worker kann erfolgreich Nachrichten an die Queues senden
- Fehler werden korrekt geloggt

### Sprint 7: S3 Backup Flow
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
- [ ] Deployment der Lambda
- [ ] E2E-Test: Create-Flow → Pinecone + S3 JSON existiert. Delete-Flow → Pinecone + S3 JSON gelöscht

**Definition of Done:**
- Nach Pinecone-Operationen werden entsprechende Events an S3Queue gesendet
- S3 Worker Lambda verarbeitet sie und speichert/löscht JSON-Dateien in S3 korrekt

### Sprint 8: Authentication & Security
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

### Sprint 9: Batch Job Scheduling & Monitoring
**Sprint Goal:** Automatisiertes Scheduling für Go Worker und umfassendes Monitoring.

**Tasks:**
- [ ] Implementierung Batch Job für Go Worker:
  - [ ] AWS EventBridge Scheduling
  - [ ] Oder alternativer Scheduling-Mechanismus
- [ ] CloudWatch Dashboards für:
  - [ ] SQS Queue Metriken
  - [ ] DynamoDB Metriken
  - [ ] Go Worker/Python API Metriken
  - [ ] Pinecone Operationen
- [ ] CloudWatch Alarme für:
  - [ ] Queue Depth
  - [ ] Fehler-Raten
  - [ ] Batch Job Failures
- [ ] Operational Logging Verbesserungen
- [ ] Automatisierte Recovery Prozesse

**Definition of Done:**
- Go Worker wird automatisch zu definierten Zeiten gestartet
- CloudWatch Dashboards zeigen System-Health
- Alarme werden bei Problemen ausgelöst
- Recovery-Prozesse funktionieren zuverlässig

### Sprint 10: Frontend Basics
**Sprint Goal:** Grundlegende Frontend-Funktionalität mit Astro und Clerk.

**Tasks:**
- [ ] Astro Projekt Setup
- [ ] Clerk Integration (Auth UI)
- [ ] Einfache Seite zum Senden von Text an Secure API Gateway
- [ ] Deployment auf S3/CloudFront

**Definition of Done:**
- Frontend kann Texteingaben an API senden
- Authentifizierung via Clerk funktioniert

### Sprint 11: Frontend Features
**Sprint Goal:** Erweiterte Frontend-Funktionen für Dokumentenverwaltung.

**Tasks:**
- [ ] File Uploader mit Client-seitiger Extraktion/Vorbereitung
- [ ] Einfacher DB-Editor (liest ggf. aus S3)
- [ ] Suchfunktion implementieren
- [ ] Status-Dashboard für Verarbeitungsprozesse

**Definition of Done:**
- Benutzer können Dateien hochladen
- Benutzer können Dokumente verwalten
- Benutzer können in indexierten Dokumenten suchen
- Status der Batch-Verarbeitung ist sichtbar

### Sprint 12: Testing & Hardening
**Sprint Goal:** Finalisierung, End-to-End Tests und System-Härtung.

**Tasks:**
- [ ] End-to-End Tests (Upload → Search)
- [ ] Load Testing mit großen Batch-Verarbeitungen
- [ ] Security Review
- [ ] Cost Optimization
- [ ] Performance Tuning
- [ ] Disaster Recovery Tests
- [ ] README und Dokumentation aktualisieren

**Definition of Done:**
- System ist sicher und performant
- Dokumentation ist vollständig
- End-to-End Tests validieren den kompletten Flow
- Code ist aufgeräumt und wartbar
- System ist kostenoptimiert

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
