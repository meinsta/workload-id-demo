// web-go/main.go - Direct SPIFFE client (no Ghostunnel needed!)
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/spiffe/go-spiffe/v2/logger"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

type Config struct {
	WebSocket        string
	WebPort          string
	BackendURL       string
	BackendSPIFFEID  string
}

type BackendResponse struct {
	SVID         string `json:"svid"`
	Name         string `json:"name"`
	Infra        string `json:"infra"`
	AcceptedSVIDs string `json:"acceptedSvids"`
}

type StatusResponse struct {
	AuthMethod    string                 `json:"authentication_method"`
	NoAPIKeys     bool                   `json:"no_api_keys"`
	CertStatus    map[string]interface{} `json:"certificate_status"`
	Note          string                 `json:"note"`
}

func main() {
	log.Println("🌐 Starting Web Service (AFTER state - Direct SPIFFE, no Ghostunnel)")
	if err := run(context.Background()); err != nil {
		log.Fatalf("Web service failed: %v", err)
	}
}

func run(ctx context.Context) error {
	config := Config{
		WebSocket:       getWebSocket(),
		WebPort:         os.Getenv("WEB_PORT"),
		BackendURL:      os.Getenv("BACKEND_URL"),
		BackendSPIFFEID: os.Getenv("BACKEND_SPIFFE_ID"),
	}

	// Default values
	if config.WebPort == "" {
		config.WebPort = "8080"
	}
	if config.BackendURL == "" {
		config.BackendURL = "https://backend:8443"
	}
	if config.BackendSPIFFEID == "" {
		config.BackendSPIFFEID = "spiffe://example.com/backend"
	}

	log.Printf("Configuration:")
	log.Printf("  Web socket: %s", config.WebSocket)
	log.Printf("  Web port: %s", config.WebPort)
	log.Printf("  Backend URL: %s", config.BackendURL)
	log.Printf("  Backend SPIFFE ID: %s", config.BackendSPIFFEID)
	log.Printf("  🔑 Direct mTLS - no Ghostunnel or API keys needed!")

	// Create SPIFFE X509 source for web client
	source, err := workloadapi.NewX509Source(ctx,
		workloadapi.WithClientOptions(workloadapi.WithAddr(config.WebSocket), workloadapi.WithLogger(logger.Std)))
	if err != nil {
		return fmt.Errorf("unable to create X509Source: %w", err)
	}
	defer source.Close()

	// Get our SVID for logging
	webSVID, err := source.GetX509SVID()
	if err != nil {
		return fmt.Errorf("unable to get web SVID: %w", err)
	}

	log.Printf("✅ Web SVID obtained:")
	log.Printf("  SPIFFE ID: %s", webSVID.ID.String())
	log.Printf("  Certificate expires: %s", webSVID.Certificates[0].NotAfter.Format(time.RFC3339))
	log.Printf("  → Identity proven by certificate, not API key")

	// Create HTTP client with SPIFFE mTLS
	backendID := spiffeid.RequireFromString(config.BackendSPIFFEID)
	tlsConfig := tlsconfig.MTLSClientConfig(source, source, tlsconfig.AuthorizeID(backendID))
	
	httpClient := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: tlsConfig,
		},
		Timeout: 10 * time.Second,
	}

	// Set up HTTP handlers
	http.HandleFunc("/backend1", handleBackend(httpClient, config.BackendURL))
	http.HandleFunc("/backend2", handleBackend(httpClient, config.BackendURL)) // Same backend for demo
	http.HandleFunc("/status", handleStatus(httpClient, config.BackendURL, source))
	http.HandleFunc("/", handleIndex)

	// Serve static files
	fs := http.FileServer(http.Dir("./public/"))
	http.Handle("/static/", http.StripPrefix("/static/", fs))

	log.Printf("🚀 Web service listening on :%s", config.WebPort)
	log.Printf("   Direct SPIFFE mTLS to backend - no proxy needed!")
	
	return http.ListenAndServe(":"+config.WebPort, nil)
}

func handleBackend(client *http.Client, backendURL string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Printf("📡 Backend request - using direct mTLS (no API keys)")
		
		// Direct HTTPS request with mTLS client certificate
		// NO Authorization header needed - identity proven by client cert
		resp, err := client.Get(backendURL)
		if err != nil {
			log.Printf("❌ Backend request failed: %v", err)
			http.Error(w, fmt.Sprintf("Backend request failed: %v", err), http.StatusServiceUnavailable)
			return
		}
		defer resp.Body.Close()

		var backendResp BackendResponse
		if err := json.NewDecoder(resp.Body).Decode(&backendResp); err != nil {
			log.Printf("❌ Failed to decode backend response: %v", err)
			http.Error(w, "Failed to decode backend response", http.StatusInternalServerError)
			return
		}

		log.Printf("✅ Backend responded - mTLS authentication successful")
		
		response := map[string]interface{}{
			"backend1": backendResp,
			"note":     "Authentication via mTLS client certificate, not API key",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func handleStatus(client *http.Client, backendURL string, source *workloadapi.X509Source) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Printf("📊 Status request - checking certificate status")

		// Get current web SVID
		webSVID, err := source.GetX509SVID()
		if err != nil {
			log.Printf("❌ Failed to get web SVID: %v", err)
			http.Error(w, "Failed to get web SVID", http.StatusInternalServerError)
			return
		}

		// Try to get backend status via direct mTLS
		var backendStatus map[string]interface{}
		whoamiResp, err := client.Get(backendURL + "/whoami")
		if err == nil {
			defer whoamiResp.Body.Close()
			json.NewDecoder(whoamiResp.Body).Decode(&backendStatus)
		}

		webNotAfter := webSVID.Certificates[0].NotAfter
		webExpiresIn := time.Until(webNotAfter).Truncate(time.Second)

		status := StatusResponse{
			AuthMethod: "Direct mTLS via Teleport Workload Identity",
			NoAPIKeys:  true,
			CertStatus: map[string]interface{}{
				"web_spiffe_id":     webSVID.ID.String(),
				"web_expires_in":    webExpiresIn.String(),
				"backend_status":    backendStatus,
				"auto_rotation":     "managed by tbot",
			},
			Note: "No Ghostunnel needed - direct SPIFFE-to-SPIFFE mTLS",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(status)
	}
}

func handleIndex(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./public/index.html")
}

func getWebSocket() string {
	if socket := os.Getenv("WEB_WORKLOAD_SOCKET"); socket != "" {
		return socket
	}
	if socket := os.Getenv("WORKLOAD_API_SOCKET"); socket != "" {
		return socket
	}
	return "unix://testing/.cache/sockets/web.sock"
}
