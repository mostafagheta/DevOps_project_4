## WeatherApp (DevOps Project 4)

![Architecture](images/image.png)

Overview
--------
This repository contains a small multi-service Weather application used for DevOps exercises. It demonstrates service separation, containerization, CI/CD pipelines (GitHub Actions), static analysis (SonarQube), dependency scanning (OWASP Dependency-Check and Trivy), and Kubernetes manifests for deploying the services.

Services
--------
- auth (Go): User authentication service that manages users and issues JWTs.
  - Source: `auth/main/main.go`
  - DB helper: `auth/authdb/authdb.go`
  - Dockerfile: `auth/Dockerfile` (multi-stage build: golang builder -> minimal alpine runtime)

- UI (Node.js / Express): Frontend server serving static pages and interacting with auth and weather services.
  - Source: `UI/app.js`, static UI in `UI/public`
  - Package manifest: `UI/package.json`
  - Dockerfile: `UI/Dockerfile`

- weather (Python / Flask): A small service that calls a third-party Weather API (RapidAPI) and returns current weather data.
  - Source: `weather/main.py`
  - Dependencies: `weather/requirements.txt`

- mysql-init: SQL initialization script for MySQL used in local K8s / Docker environments.
  - `mysql-init/init.sql` creates the `weatherapp` schema and `users` table.

Kubernetes manifests
--------------------
Kubernetes manifests for each service live under `kubernetes/` and `K8S/` directories (the repo contains multiple K8s folders used for different deployment flows). Example manifests used in CI/CD are under `kubernetes/`:

- `kubernetes/authentication/deployment.yaml` and `service.yaml` — deployment/service for the auth service
- `kubernetes/ui/*` — UI deployment/service/ingress
- `kubernetes/weather/*` — weather deployment and service

CI / CD (GitHub Actions)
------------------------
There are two main workflows in `.github/workflows/`:

- `ui-service.yml` — Serial pipeline for the UI service with these jobs:
  1. build-and-test (npm ci, build, placeholder test)
 2. sonar-scan (SonarQube analysis)
 3. dependency-check (OWASP Dependency-Check)
 4. docker-build (build Docker image, save as artifact)
 5. trivy-scan (download artifact, docker load, scan image; uploads JSON report)
 6. docker-push (download artifact, docker load, push to Docker Hub)
 7. update-manifests (update K8s manifest image tags on `main`)

- `auth-service.yml` — Mirrors the UI pipeline but for the Go `auth` service:
  - build-and-test (setup-go, go mod download, go build, go test)
  - sonar-scan
  - dependency-check
  - docker-build (build image and save artifact)
  - trivy-scan (download, load, scan, upload report)
  - docker-push

CI Security & Diagnostics
------------------------
- Sonar: Workflows include SonarQube steps and print `.scannerwork/report-task.txt` for troubleshooting if the scanner fails to upload results.
- Trivy: Workflows save the built Docker image as an artifact and load it into subsequent jobs. This avoids problems where Trivy can't find the image in the runner or pull remote images (MANIFEST_UNKNOWN). Trivy JSON reports are uploaded as job artifacts named `trivy-report` (UI) and `trivy-report-auth` (auth).
- OWASP Dependency-Check: Runs on the project directory and uploads an HTML report as an artifact.

Security remediation performed
----------------------------
- UI (Node.js):
  - Added placeholder `build` and `test` scripts so CI/sonar steps run reliably.
  - Ran `npm audit` and applied fixes, including `npm audit fix --force` to resolve transitive high/critical vulnerabilities. Key direct dependencies were updated (e.g., `axios`, `jsonwebtoken`) and `package-lock.json` was updated and committed.

- Auth (Go):
  - Replaced the old `dgrijalva/jwt-go` usage by adding `github.com/golang-jwt/jwt/v4` in `auth/go.mod`.
  - Bumped `github.com/gin-contrib/cors` to `v1.6.0` to address known CVEs.
  - Upgraded `golang.org/x/crypto` and `golang.org/x/net` to more recent versions (see `auth/go.mod`).
  - Fixed a malformed `go` directive (`go 1.23.0` → `go 1.23`) so `go mod download` and CI builds run correctly.

Security TODOs (recommended, not yet implemented)
------------------------------------------------
- Replace MD5 password hashing in `auth/authdb/authdb.go` with bcrypt or Argon2.
- Avoid building SQL via `fmt.Sprintf` — use prepared statements to prevent SQL injection.
- Update JWT usages to the v4 API (`jwt.NewWithClaims`, `jwt.RegisteredClaims`) and enforce explicit signing methods.

How to run locally (quickstart)
-------------------------------
1. Start a MySQL instance (e.g., Docker) and initialize the schema with `mysql-init/init.sql`.

2. Run the auth service locally (in `auth/`):
```bash
cd auth
go mod tidy
go build ./...
./app # or go run ./main
```

3. Run the weather service (in `weather/`):
```bash
cd weather
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python main.py
```

4. Run the UI (in `UI/`):
```bash
cd UI
npm ci
npm start
```

CI Secrets (set these in your repository settings)
------------------------------------------------
- `SONAR_TOKEN`, `SONAR_HOST_URL` — SonarQube authentication and host
- `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` — For pushing images
- `APIKEY` — RapidAPI key used by the `weather` service (for local runs, set in env)

Notes and caveats
-----------------
- Docker image base selection impacts Trivy results: `node:20-alpine` and `alpine:latest` are used; image-level OS CVEs may still surface in Trivy scans depending on upstream patches.
- `auth/authdb/authdb.go` currently uses MD5 hashing and unparameterized SQL — this is insecure for production and should be refactored (see TODOs above).

Contact / Maintainer
--------------------
Ahmed Elfakharany

License
-------
This project has no explicit license file. Add a LICENSE if you plan to open-source it.
