FROM node:20-alpine
WORKDIR /usr/src/app
COPY package*.json ./
# Upgrade npm to pick up patched transitive dependencies (reduces image-level vulnerabilities)
RUN npm install -g npm@latest
RUN npm install
COPY . .
EXPOSE 3000
ENTRYPOINT ["node"]
CMD [ "app.js" ]