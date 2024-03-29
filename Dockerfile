FROM node:21-bullseye-slim

WORKDIR /webapp

COPY package*.json .

COPY . .

CMD [ "node", "app.js" ]

USER node

EXPOSE 8080
