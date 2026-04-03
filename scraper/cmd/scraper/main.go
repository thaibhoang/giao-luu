package main

import (
	"fmt"
	"log"
	"os"
)

// Version được gán lúc build: -ldflags "-X main.Version=..."
var Version = "dev"

func main() {
	log.SetPrefix("scraper ")
	log.SetFlags(0)

	baseURL := os.Getenv("RAILS_INTERNAL_URL")
	if baseURL == "" {
		baseURL = "http://localhost:3000"
	}

	fmt.Printf("sportmatch scraper %s (RAILS_INTERNAL_URL=%q)\n", Version, baseURL)
	log.Println("stub: pipeline fetch → LLM → ingest sẽ nối vào đây (xem docs/SCRAPER_AGENT.md)")
}
