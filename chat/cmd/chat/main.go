// main.go — HTTP server cho Go Chat Service (ADR-005).
// Port: 8081 (mặc định). Env: CHAT_HMAC_SECRET, DATABASE_URL, RAILS_INTERNAL_URL.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/thaibhoang/giao-luu/chat/internal/handler"
	"github.com/thaibhoang/giao-luu/chat/internal/hub"
	"github.com/thaibhoang/giao-luu/chat/internal/notify"
	"github.com/thaibhoang/giao-luu/chat/internal/store"
)

func main() {
	log.SetPrefix("chat ")
	log.SetFlags(log.LstdFlags)

	cfg := loadConfig()

	// Kết nối PostgreSQL
	pool, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("cannot connect to database: %v", err)
	}
	defer pool.Close()

	if err := pool.Ping(context.Background()); err != nil {
		log.Fatalf("database ping failed: %v", err)
	}
	log.Println("database connected")

	// Khởi tạo dependencies
	h := hub.New()
	go h.Run()

	s := store.New(pool)
	n := notify.New(cfg.RailsInternalURL, cfg.ChatHMACSecret)

	wsHandler := handler.NewWSHandler(h, s, n, cfg.ChatHMACSecret)

	// HTTP routes
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", wsHandler.ServeWS)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 0, // WebSocket — không đặt timeout write
		IdleTimeout:  120 * time.Second,
	}

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("chat service listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-quit
	log.Println("shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("shutdown error: %v", err)
	}
	log.Println("stopped")
}

type config struct {
	Port             string
	DatabaseURL      string
	ChatHMACSecret   string
	RailsInternalURL string
}

func loadConfig() config {
	cfg := config{
		Port:             getEnv("PORT", "8081"),
		DatabaseURL:      mustGetEnv("DATABASE_URL"),
		ChatHMACSecret:   mustGetEnv("CHAT_HMAC_SECRET"),
		RailsInternalURL: getEnv("RAILS_INTERNAL_URL", "http://web:80"),
	}
	return cfg
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func mustGetEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("%s is required", key)
	}
	return v
}
