package middleware

import (
	"encoding/json"
	"log"
	"net/http"
)

func Auth(apiKey string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Allow /health without auth for k8s probes
		if r.URL.Path == "/health" {
			next.ServeHTTP(w, r)
			return
		}

		// Allow Strava OAuth bootstrap and callback without auth
		if r.Method == http.MethodGet && (r.URL.Path == "/auth/strava" || r.URL.Path == "/auth/strava/callback" || r.URL.Path == "/auth/strava/success") {
			next.ServeHTTP(w, r)
			return
		}

		// Allow GET /images/* without auth (for viewing)
		if r.Method == http.MethodGet && len(r.URL.Path) >= 7 && r.URL.Path[:7] == "/images" {
			next.ServeHTTP(w, r)
			return
		}

		providedKey := r.Header.Get("X-API-Key")
		if providedKey == "" {
			log.Printf("[AUTH] Missing API key for %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "missing API key"})
			return
		}

		if providedKey != apiKey {
			log.Printf("[AUTH] Invalid API key for %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "invalid API key"})
			return
		}

		next.ServeHTTP(w, r)
	})
}
