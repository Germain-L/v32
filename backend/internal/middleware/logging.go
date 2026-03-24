package middleware

import (
	"log"
	"net/http"
	"time"
)

// Logging middleware logs all incoming requests
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Wrap response writer to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		// Log request
		log.Printf("[REQ] %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		
		next.ServeHTTP(wrapped, r)
		
		// Log response
		duration := time.Since(start)
		log.Printf("[RES] %s %s -> %d (%v)", r.Method, r.URL.Path, wrapped.statusCode, duration)
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}
