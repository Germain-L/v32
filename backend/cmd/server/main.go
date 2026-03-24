package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gmn/v32-backend/internal/handlers"
	"github.com/gmn/v32-backend/internal/middleware"
	"github.com/gmn/v32-backend/internal/storage"
)

func main() {
	apiKey := os.Getenv("API_KEY")
	if apiKey == "" {
		log.Fatal("API_KEY environment variable is required")
	}

	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "/data/meals.db"
	}

	uploadPath := os.Getenv("UPLOAD_PATH")
	if uploadPath == "" {
		uploadPath = "/data/uploads"
	}

	// Initialize storage
	store, err := storage.New(dbPath, uploadPath)
	if err != nil {
		log.Fatalf("Failed to initialize storage: %v", err)
	}
	defer store.Close()

	// Initialize handlers
	h := handlers.New(store)

	// Setup router with middleware
	mux := h.Routes()
	authMux := middleware.Auth(apiKey, mux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, authMux))
}
