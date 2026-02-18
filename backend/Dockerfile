FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY ./src ./src

RUN CGO_ENABLED=0 GOOS=linux go build -o /portfolio-api ./src/main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /portfolio-api .

RUN adduser -D gouser
USER gouser

EXPOSE 3000

CMD ["./portfolio-api"]
