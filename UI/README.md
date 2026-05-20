# UI Service

This UI service is scanned by SonarQube in CI. To make the Sonar scan and quality gate work in GitHub Actions, set the following repository secrets:

- SONAR_TOKEN: your SonarQube token
- SONAR_HOST_URL: the URL of your SonarQube server (e.g. https://sonarcloud.io)

If the `SonarQube Quality Gate` step fails with a 403 when calling Sonar, check that:

1. The `SONAR_TOKEN` has the proper permissions to access the project specified by `-Dsonar.projectKey`.
2. The `SONAR_HOST_URL` is reachable from GitHub Actions and is the same host used when running the scanner.
3. The scanner produced a `report-task.txt` file under `./UI/.scannerwork/report-task.txt` — the workflow now prints this file during CI for debugging.

For local debugging, you can run the Sonar scanner and ensure `./UI/.scannerwork/report-task.txt` is created before the quality gate step runs.
