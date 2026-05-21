Changelog for auth module

- 2026-05-21: Upgraded dependencies to address Trivy findings:
  - github.com/golang-jwt/jwt/v4 v4.5.2 (replaces dgrijalva/jwt-go)
  - github.com/gin-contrib/cors v1.6.0
  - updated indirect golang.org/x/* modules

Follow-up: Replace MD5 with bcrypt and parameterize SQL queries in authdb.
