FROM golang:1.22.5-alpine3.20

WORKDIR /app

COPY . .

RUN go mod download

RUN go build -o main .

CMD "./main"