.PHONY: run build test clean migrate

run:
	go run ./cmd/server/

build:
	CGO_ENABLED=0 go build -o bin/server ./cmd/server/

test:
	go test ./... -v

clean:
	rm -rf bin/ uploads/

migrate:
	psql $(DATABASE_URL) -f migrations/001_initial_schema.sql
