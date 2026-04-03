package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Version được gán lúc build: -ldflags "-X main.Version=..."
var Version = "dev"

func main() {
	log.SetPrefix("scraper ")
	log.SetFlags(0)

	cfg := loadConfig()
	if cfg.HMACSecret == "" {
		log.Fatal("SCRAPER_HMAC_SECRET is required")
	}
	rawText := os.Getenv("SCRAPER_RAW_TEXT")
	if rawText == "" {
		rawText = "Cần 2 nam giao lưu cầu lông tối nay 19:00-21:00 sân 583 Nguyễn Trãi, trình trung bình yếu, phí 50k"
	}
	sourceURL := os.Getenv("SCRAPER_SOURCE_URL")
	if sourceURL == "" {
		sourceURL = fmt.Sprintf("https://example.com/post/%d", time.Now().Unix())
	}
	location := os.Getenv("SCRAPER_LOCATION_NAME")
	if location == "" {
		location = "Sân 583 Nguyễn Trãi, Hồ Chí Minh"
	}
	sport := "badminton"
	if strings.Contains(strings.ToLower(rawText), "pickle") {
		sport = "pickleball"
	}
	now := time.Now().UTC()
	start := now.Add(24 * time.Hour).Truncate(time.Hour)
	end := start.Add(2 * time.Hour)

	lat, lng, fromCache := resolveGeocode(location)
	payload := ingestPayload{
		SchemaVersion: 2,
		Extracted: extractedPayload{
			Sport:         sport,
			Location:      location,
			StartTime:     start.Format(time.RFC3339),
			EndTime:       end.Format(time.RFC3339),
			SlotsNeeded:   2,
			SkillLevelMin: "trung_binh_yeu",
			SkillLevelMax: "trung_binh_plus",
			Price:         intPtr(50000),
			ContactInfo:   sourceURL,
			Title:         "Ingest từ scraper",
			Body:          rawText,
		},
		SourceURL: sourceURL,
		RawText:   rawText,
		Geocode: geocodePayload{
			Lat:       floatPtr(lat),
			Lng:       floatPtr(lng),
			FromCache: fromCache,
		},
	}

	if err := ingestWithRetry(cfg, payload); err != nil {
		log.Fatalf("ingest failed: %v", err)
	}

	fmt.Printf("sportmatch scraper %s (RAILS_INTERNAL_URL=%q)\n", Version, cfg.RailsInternalURL)
	log.Println("ingest completed")
}

type config struct {
	RailsInternalURL string
	HMACSecret       string
	MaxRetries       int
}

type ingestPayload struct {
	SchemaVersion int              `json:"schema_version"`
	Extracted     extractedPayload `json:"extracted"`
	SourceURL     string           `json:"source_url"`
	RawText       string           `json:"raw_text"`
	Geocode       geocodePayload   `json:"geocode"`
}

type extractedPayload struct {
	Sport         string `json:"sport"`
	Location      string `json:"location_name"`
	StartTime     string `json:"start_time"`
	EndTime       string `json:"end_time"`
	SlotsNeeded   int    `json:"slots_needed"`
	SkillLevelMin string `json:"skill_level_min"`
	SkillLevelMax string `json:"skill_level_max"`
	Price         *int   `json:"price_estimate,omitempty"`
	ContactInfo   string `json:"contact_info"`
	Title         string `json:"title,omitempty"`
	Body          string `json:"body,omitempty"`
}

type geocodePayload struct {
	Lat       *float64 `json:"lat,omitempty"`
	Lng       *float64 `json:"lng,omitempty"`
	FromCache bool     `json:"from_cache"`
}

func loadConfig() config {
	baseURL := os.Getenv("RAILS_INTERNAL_URL")
	if baseURL == "" {
		baseURL = "http://localhost:3000"
	}
	maxRetries := 4
	if v := os.Getenv("SCRAPER_MAX_RETRIES"); v != "" {
		if parsed, err := strconv.Atoi(v); err == nil && parsed > 0 {
			maxRetries = parsed
		}
	}
	return config{
		RailsInternalURL: strings.TrimRight(baseURL, "/"),
		HMACSecret:       os.Getenv("SCRAPER_HMAC_SECRET"),
		MaxRetries:       maxRetries,
	}
}

func ingestWithRetry(cfg config, payload ingestPayload) error {
	endpoint := cfg.RailsInternalURL + "/internal/v1/listings/import"
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal payload: %w", err)
	}
	client := &http.Client{Timeout: 10 * time.Second}
	for attempt := 1; attempt <= cfg.MaxRetries; attempt++ {
		ts := strconv.FormatInt(time.Now().Unix(), 10)
		sig := signBody(cfg.HMACSecret, ts, body)
		req, err := http.NewRequest(http.MethodPost, endpoint, bytes.NewReader(body))
		if err != nil {
			return fmt.Errorf("build request: %w", err)
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-SportMatch-Timestamp", ts)
		req.Header.Set("X-SportMatch-Signature", sig)

		resp, err := client.Do(req)
		if err == nil && resp != nil && resp.StatusCode >= 200 && resp.StatusCode < 300 {
			_ = resp.Body.Close()
			return nil
		}
		if resp != nil {
			_ = resp.Body.Close()
		}
		sleep := time.Duration(attempt*attempt)*time.Second + time.Duration(rand.Intn(250))*time.Millisecond
		log.Printf("attempt %d failed, retrying in %s", attempt, sleep)
		time.Sleep(sleep)
	}
	return fmt.Errorf("all retries exhausted")
}

func signBody(secret, timestamp string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(timestamp))
	_, _ = mac.Write([]byte("."))
	_, _ = mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}

func parseFloatEnv(name string, fallback float64) float64 {
	v := os.Getenv(name)
	if v == "" {
		return fallback
	}
	parsed, err := strconv.ParseFloat(v, 64)
	if err != nil {
		return fallback
	}
	return parsed
}

func intPtr(v int) *int           { return &v }
func floatPtr(v float64) *float64 { return &v }

func resolveGeocode(location string) (float64, float64, bool) {
	cachePath := os.Getenv("SCRAPER_GEOCODE_CACHE_FILE")
	if cachePath == "" {
		cachePath = ".cache/geocode.json"
	}

	cache := map[string][2]float64{}
	if content, err := os.ReadFile(cachePath); err == nil {
		_ = json.Unmarshal(content, &cache)
	}

	key := strings.ToLower(strings.TrimSpace(location))
	if coords, ok := cache[key]; ok {
		return coords[0], coords[1], true
	}

	lat := parseFloatEnv("SCRAPER_LAT", 10.8231)
	lng := parseFloatEnv("SCRAPER_LNG", 106.6297)
	cache[key] = [2]float64{lat, lng}
	_ = os.MkdirAll(filepath.Dir(cachePath), 0o755)
	if encoded, err := json.Marshal(cache); err == nil {
		_ = os.WriteFile(cachePath, encoded, 0o644)
	}
	return lat, lng, false
}
