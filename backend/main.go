package main

import (
	"context"
	"encoding/json"
	"flag"
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
	SocketPath             string // Legacy field name for compatibility
	WorkloadSocket         string // New preferred field name
	ApprovedClientSPIFFEID string
	Name                   string
	Infra                  string
	Port                   string
}

func main() {
	log.Println("Server is starting...")
	if err := run(context.Background()); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func run(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// Parse command line flags
	workloadSocket := flag.String("workload-socket", "", "Workload API socket address")
	flag.Parse()

	config := Config{
		// Legacy compatibility
		SocketPath:             os.Getenv("BACKEND_SOCKET_PATH"),
		// New workload socket configuration with multiple sources
		WorkloadSocket:         getWorkloadSocket(*workloadSocket),
		ApprovedClientSPIFFEID: os.Getenv("BACKEND_APPROVED_CLIENT_SPIFFEID"),
		Name:                   os.Getenv("BACKEND_NAME"),
		Infra:                  os.Getenv("BACKEND_INFRA"),
		Port:                   os.Getenv("BACKEND_PORT"),
	}

	// Use WorkloadSocket preferentially, fallback to legacy SocketPath
	socketAddr := config.WorkloadSocket
	if socketAddr == "" {
		socketAddr = config.SocketPath
	}

	log.Printf("Using workload API socket: %s", socketAddr)

	// Create a `workloadapi.X509Source`
	source, err := workloadapi.NewX509Source(ctx,
		workloadapi.WithClientOptions(workloadapi.WithAddr(socketAddr), workloadapi.WithLogger(logger.Std)))
	if err != nil {
		return fmt.Errorf("unable to create X509Source: %w", err)
	}
	defer source.Close()

	svid, err := source.GetX509SVID()
	if err != nil {
		return fmt.Errorf("unable to get X509SVID: %w", err)
	}
	
	// Log SVID details on startup - this shows identity without API keys
	log.Printf("✓ SVID obtained successfully")
	log.Printf("  SPIFFE ID: %s", svid.ID.String())
	log.Printf("  Certificate expires: %s", svid.Certificates[0].NotAfter.Format(time.RFC3339))
	log.Printf("  Time until expiry: %v", time.Until(svid.Certificates[0].NotAfter).Truncate(time.Second))
	log.Printf("  → No API keys needed - identity is cryptographic")

	clientID := spiffeid.RequireFromString(config.ApprovedClientSPIFFEID)

	tlsConfig := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeID(clientID))
	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", config.Port),
		TLSConfig:         tlsConfig,
		ReadHeaderTimeout: time.Second * 10,
	}

	// Set up a `/whoami` resource handler - shows identity without API keys
	http.HandleFunc("/whoami", func(w http.ResponseWriter, r *http.Request) {
		log.Println("WhoAmI request received")
		
		// Get current SVID (may have rotated since startup)
		currentSVID, err := source.GetX509SVID()
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get current SVID: %v", err), http.StatusInternalServerError)
			return
		}
		
		notAfter := currentSVID.Certificates[0].NotAfter
		expiresIn := time.Until(notAfter).Truncate(time.Second)
		
		data := map[string]interface{}{
			"spiffe_id": currentSVID.ID.String(),
			"not_after":  notAfter.Format(time.RFC3339),
			"expires_in": expiresIn.String(),
			"note":       "Authentication via mTLS certificate, not API key",
		}
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(data)
	})

	// Set up a `/` resource handler
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Request received - Serving Response")
		// NOTE: No Authorization header validation here - that would be the legacy API key pattern
		// Instead, mTLS client certificate validation is handled by tlsConfig.AuthorizeID above

		data := make(map[string]string)
		data["svid"] = svid.ID.String()
		data["name"] = config.Name
		data["infra"] = config.Infra
		data["acceptedSvids"] = config.ApprovedClientSPIFFEID

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(data)
	})

	log.Printf("Server listening on %s", server.Addr)
	if err := server.ListenAndServeTLS("", ""); err != nil {
		return fmt.Errorf("failed to serve: %w", err)
	}

	return nil
}

// getWorkloadSocket determines the workload API socket address from multiple sources
// Priority: 1) flag argument, 2) WORKLOAD_API_SOCKET env, 3) default repo-local socket
func getWorkloadSocket(flagValue string) string {
	if flagValue != "" {
		return flagValue
	}
	
	if envValue := os.Getenv("WORKLOAD_API_SOCKET"); envValue != "" {
		return envValue
	}
	
	// Default to repo-local socket for local demo
	return "unix://testing/.cache/sockets/backend.sock"
}
