.PHONY: build up up-ssl up-ssl-custom down restart restart-ssl restart-ssl-custom logs clean create-user setup test-upload test-download test-delete help

USERNAME ?= admin
PASSWORD ?= admin123
TARGET ?= 192.168.1.100
HTTP_PORT ?= 9000
HTTPS_PORT ?= 9443
SSL_MODE ?= auto
SSL_CN ?= localhost
SSL_ORG ?= WebDAV Server
SSL_DAYS ?= 365

help:
	@echo "NGINX WebDAV Docker Setup"
	@echo "========================="
	@echo ""
	@echo "Available commands:"
	@echo "  help            Show this help message"
	@echo "  setup           Initial setup - creates directories and default user"
	@echo "  create-user     Create a new user (USERNAME=user PASSWORD=pass)"
	@echo "  build           Build the Docker image"
	@echo "  up              Start the WebDAV server (HTTP mode)"
	@echo "  up-ssl          Start the WebDAV server (HTTPS mode, auto-generate cert)"
	@echo "  up-ssl-custom   Start the WebDAV server (HTTPS mode, use custom cert)"
	@echo "  down            Stop the WebDAV server"
	@echo "  restart         Restart the WebDAV server"
	@echo "  logs            Show server logs"
	@echo "  clean           Remove all containers, volumes, and generated files"
	@echo "  clean-all       Remove everything including data"
	@echo "  status          Check server status"
	@echo ""
	@echo "Test commands (HTTP mode):"
	@echo "  test-upload     Test file upload"
	@echo "  test-download   Test file download"
	@echo "  test-delete     Test file deletion"
	@echo "  test-list       List files via WebDAV PROPFIND"
	@echo "  test-all        Run all tests"
	@echo ""
	@echo "Test commands (HTTPS mode):"
	@echo "  test-upload-ssl     Test file upload (HTTPS)"
	@echo "  test-download-ssl   Test file download (HTTPS)"
	@echo "  test-delete-ssl     Test file deletion (HTTPS)"
	@echo "  test-list-ssl       List files via WebDAV PROPFIND (HTTPS)"
	@echo "  test-all-ssl        Run all tests (HTTPS)"
	@echo ""
	@echo "SSL Certificate commands:"
	@echo "  gen-cert        Generate self-signed certificate manually"
	@echo "  show-cert       Show certificate details"
	@echo "  clean-cert      Remove SSL certificates"
	@echo ""
	@echo "Usage examples:"
	@echo "  make setup                              # Initial setup"
	@echo "  make up                                 # Start in HTTP mode"
	@echo "  make up-ssl                             # Start in HTTPS mode (auto-generate cert)"
	@echo "  make up-ssl SSL_CN=webdav.example.com   # HTTPS with custom domain cert"
	@echo "  make up-ssl-custom                      # Start in HTTPS mode (use custom cert)"
	@echo "  make create-user USERNAME=jane PASSWORD=pass456"
	@echo ""
	@echo "SSL Modes:"
	@echo "  SSL_MODE=auto   Auto-generate self-signed certificate if missing (default)"
	@echo "  SSL_MODE=custom Use existing certificates (fails if not found)"
	@echo ""
	@echo "For custom certificates, copy your files before starting:"
	@echo "  cp /path/to/your.crt data/ssl/server.crt"
	@echo "  cp /path/to/your.key data/ssl/server.key"
	@echo "  make up-ssl-custom"
	@echo ""
	@echo "Environment variables:"
	@echo "  TARGET          Target host (default: $(TARGET))"
	@echo "  HTTP_PORT       HTTP port (default: $(HTTP_PORT))"
	@echo "  HTTPS_PORT      HTTPS port (default: $(HTTPS_PORT))"
	@echo "  SSL_MODE        Certificate mode: auto|custom (default: $(SSL_MODE))"
	@echo "  SSL_CN          Certificate Common Name (default: $(SSL_CN))"
	@echo "  SSL_ORG         Certificate Organization (default: $(SSL_ORG))"
	@echo "  SSL_DAYS        Certificate validity in days (default: $(SSL_DAYS))"

setup:
	@echo "Setting up NGINX WebDAV..."
	@mkdir -p webdav data/ssl
	@chmod 755 webdav
	@chmod 700 data/ssl
	@if [ ! -f data/htpasswd ]; then \
		echo "Creating htpasswd file with user: $(USERNAME)"; \
		htpasswd -cb data/htpasswd $(USERNAME) $(PASSWORD); \
		echo "✓ User created: $(USERNAME)"; \
	else \
		echo "htpasswd file already exists. Use 'make create-user' to add more users."; \
	fi
	@echo "✓ Setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run 'make up' for HTTP mode or 'make up-ssl' for HTTPS mode"
	@echo "  2. Access WebDAV at:"
	@echo "     - HTTP:  http://$(TARGET):$(HTTP_PORT)"
	@echo "     - HTTPS: https://$(TARGET):$(HTTPS_PORT)"
	@echo "  3. Username: $(USERNAME)"
	@echo "  4. Password: $(PASSWORD)"

create-user:
	@if [ ! -f data/htpasswd ]; then \
		echo "Creating htpasswd file..."; \
		htpasswd -cb data/htpasswd $(USERNAME) $(PASSWORD); \
	else \
		echo "Adding user to existing htpasswd file..."; \
		htpasswd -b data/htpasswd $(USERNAME) $(PASSWORD); \
	fi
	@echo "✓ User added/updated: $(USERNAME)"

gen-cert:
	@echo "Generating self-signed SSL certificate..."
	@mkdir -p data/ssl
	@openssl req -x509 -nodes -days $(SSL_DAYS) -newkey rsa:2048 \
		-keyout data/ssl/server.key \
		-out data/ssl/server.crt \
		-subj "/C=FR/ST=Ile-de-France/L=Paris/O=${SSL_ORG}/CN=${SSL_CN}" \
		-addext "subjectAltName=DNS:$(SSL_CN),DNS:localhost,IP:127.0.0.1"
	@chmod 600 data/ssl/server.key
	@chmod 644 data/ssl/server.crt
	@echo "✓ SSL certificate generated"
	@echo "  Common Name: $(SSL_CN)"
	@echo "  Valid for: $(SSL_DAYS) days"

show-cert:
	@if [ -f data/ssl/server.crt ]; then \
		echo "Certificate details:"; \
		openssl x509 -in data/ssl/server.crt -noout -subject -dates -issuer; \
	else \
		echo "No certificate found. Run 'make gen-cert' or 'make up-ssl' to generate one."; \
	fi

clean-cert:
	@rm -f data/ssl/server.crt data/ssl/server.key
	@echo "✓ SSL certificates removed"

build:
	docker-compose build

up:
	@mkdir -p data/ssl
	SSL_ENABLED=false HTTP_PORT=$(HTTP_PORT) HTTPS_PORT=$(HTTPS_PORT) docker-compose up -d
	@echo "✓ NGINX WebDAV server started (HTTP mode)"
	@echo "  Access at: http://$(TARGET):$(HTTP_PORT)"

up-ssl:
	@mkdir -p data/ssl
	SSL_ENABLED=true SSL_MODE=auto HTTP_PORT=$(HTTP_PORT) HTTPS_PORT=$(HTTPS_PORT) \
		SSL_CN=$(SSL_CN) SSL_ORG="$(SSL_ORG)" SSL_DAYS=$(SSL_DAYS) \
		docker-compose up -d
	@echo "✓ NGINX WebDAV server started (HTTPS mode, auto-generated cert)"
	@echo "  HTTP:  http://$(TARGET):$(HTTP_PORT) (redirects to HTTPS)"
	@echo "  HTTPS: https://$(TARGET):$(HTTPS_PORT)"

up-ssl-custom:
	@if [ ! -f data/ssl/server.crt ] || [ ! -f data/ssl/server.key ]; then \
		echo "ERROR: Custom certificates not found!"; \
		echo "Please copy your certificates first:"; \
		echo "  cp /path/to/your.crt data/ssl/server.crt"; \
		echo "  cp /path/to/your.key data/ssl/server.key"; \
		exit 1; \
	fi
	SSL_ENABLED=true SSL_MODE=custom HTTP_PORT=$(HTTP_PORT) HTTPS_PORT=$(HTTPS_PORT) \
		docker-compose up -d
	@echo "✓ NGINX WebDAV server started (HTTPS mode, custom cert)"
	@echo "  HTTP:  http://$(TARGET):$(HTTP_PORT) (redirects to HTTPS)"
	@echo "  HTTPS: https://$(TARGET):$(HTTPS_PORT)"

down:
	docker-compose down
	@echo "✓ NGINX WebDAV server stopped"

restart: down up

restart-ssl: down up-ssl

restart-ssl-custom: down up-ssl-custom

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	@echo "✓ Containers and volumes removed"
	@echo "Note: webdav directory, data/htpasswd, and SSL certs are preserved"

clean-all: clean
	rm -rf webdav data
	@echo "✓ All data removed"

test-upload:
	@echo "Testing file upload (HTTP)..."
	@echo "This is a test file" > /tmp/test.txt
	@curl -u $(USERNAME):$(PASSWORD) -T /tmp/test.txt http://$(TARGET):$(HTTP_PORT)/test.txt
	@echo "\n✓ Upload test complete"

test-download:
	@echo "Testing file download (HTTP)..."
	@curl -u $(USERNAME):$(PASSWORD) http://$(TARGET):$(HTTP_PORT)/test.txt
	@echo "\n✓ Download test complete"

test-delete:
	@echo "Testing file deletion (HTTP)..."
	@curl -u $(USERNAME):$(PASSWORD) -X DELETE http://$(TARGET):$(HTTP_PORT)/test.txt
	@echo "\n✓ Delete test complete"

test-list:
	@echo "Testing directory listing (HTTP)..."
	@curl -u $(USERNAME):$(PASSWORD) -X PROPFIND http://$(TARGET):$(HTTP_PORT)/ -H "Depth: 1"
	@echo "\n✓ List test complete"

test-all: test-upload test-download test-list test-delete
	@echo "\n✓ All HTTP tests complete!"

test-upload-ssl:
	@echo "Testing file upload (HTTPS)..."
	@echo "This is a test file" > /tmp/test.txt
	@curl -k -u $(USERNAME):$(PASSWORD) -T /tmp/test.txt https://$(TARGET):$(HTTPS_PORT)/test.txt
	@echo "\n✓ Upload test complete"

test-download-ssl:
	@echo "Testing file download (HTTPS)..."
	@curl -k -u $(USERNAME):$(PASSWORD) https://$(TARGET):$(HTTPS_PORT)/test.txt
	@echo "\n✓ Download test complete"

test-delete-ssl:
	@echo "Testing file deletion (HTTPS)..."
	@curl -k -u $(USERNAME):$(PASSWORD) -X DELETE https://$(TARGET):$(HTTPS_PORT)/test.txt
	@echo "\n✓ Delete test complete"

test-list-ssl:
	@echo "Testing directory listing (HTTPS)..."
	@curl -k -u $(USERNAME):$(PASSWORD) -X PROPFIND https://$(TARGET):$(HTTPS_PORT)/ -H "Depth: 1"
	@echo "\n✓ List test complete"

test-all-ssl: test-upload-ssl test-download-ssl test-list-ssl test-delete-ssl
	@echo "\n✓ All HTTPS tests complete!"

test-redirect:
	@echo "Testing HTTP to HTTPS redirect..."
	@curl -I http://$(TARGET):$(HTTP_PORT)/
	@echo "✓ Redirect test complete (should show 301 redirect in HTTPS mode)"

status:
	@docker-compose ps