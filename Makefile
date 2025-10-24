.PHONY: build up down restart logs clean create-user setup test-upload test-download test-delete help

USERNAME ?= admin
PASSWORD ?= admin123
TARGET ?= 192.168.1.100
TARGET_PORT ?= 9000

help:
	@echo "NGINX WebDAV Docker Setup"
	@echo "========================="
	@echo ""
	@echo "Available commands:"
	@echo "  help            Show this help message"
	@echo "  setup           Initial setup - creates directories and default user"
	@echo "  create-user     Create a new user (USERNAME=user PASSWORD=pass)"
	@echo "  build           Build the Docker image"
	@echo "  up              Start the WebDAV server"
	@echo "  down            Stop the WebDAV server"
	@echo "  restart         Restart the WebDAV server"
	@echo "  logs            Show server logs"
	@echo "  clean           Remove all containers, volumes, and generated files"
	@echo "  clean-all       Remove everything including data"
	@echo "  test-upload     Test file upload (creates test.txt and uploads it)"
	@echo "  test-download   Test file download"
	@echo "  test-delete     Test file deletion"
	@echo "  test-list       List files via WebDAV PROPFIND"
	@echo "  test-all        Run all tests"
	@echo "  status          Check server status"
	@echo ""
	@echo "Usage examples:"
	@echo "  make setup                          # Initial setup with default credentials"
	@echo "  make setup USERNAME=john PASSWORD=secret123  # Setup with custom credentials"
	@echo "  make create-user USERNAME=jane PASSWORD=pass456  # Add another user"

setup:
	@echo "Setting up NGINX WebDAV..."
	@mkdir -p webdav data
	@chmod 755 webdav
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
	@echo "  1. Run 'make up' to start the server"
	@echo "  2. Access WebDAV at http://$(TARGET):$(TARGET_PORT)"
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

build:
	docker-compose build

up:
	docker-compose up -d
	@echo "✓ NGINX WebDAV server started!"
	@echo "  Access at: http://$(TARGET):$(TARGET_PORT)"

down:
	docker-compose down
	@echo "✓ NGINX WebDAV server stopped"

restart: down up

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	@echo "✓ Containers and volumes removed"
	@echo "Note: webdav directory and data/htpasswd are preserved"

clean-all: clean
	rm -rf webdav data
	@echo "✓ All data removed"

test-upload:
	@echo "Testing file upload..."
	@echo "This is a test file" > /tmp/test.txt
	@curl -u $(USERNAME):$(PASSWORD) -T /tmp/test.txt http://$(TARGET):$(TARGET_PORT)/test.txt
	@echo "\n✓ Upload test complete"

test-download:
	@echo "Testing file download..."
	@curl -u $(USERNAME):$(PASSWORD) http://$(TARGET):$(TARGET_PORT)/test.txt
	@echo "\n✓ Download test complete"

test-delete:
	@echo "Testing file deletion..."
	@curl -u $(USERNAME):$(PASSWORD) -X DELETE http://$(TARGET):$(TARGET_PORT)/test.txt
	@echo "\n✓ Delete test complete"

test-list:
	@echo "Testing directory listing..."
	@curl -u $(USERNAME):$(PASSWORD) -X PROPFIND http://$(TARGET):$(TARGET_PORT)/ -H "Depth: 1"
	@echo "\n✓ List test complete"

test-all: test-upload test-download test-list test-delete
	@echo "\n✓ All tests complete!"

status:
	@docker-compose ps