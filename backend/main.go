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
	SocketPath             string
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

	config := Config{
		SocketPath:             os.Getenv("BACKEND_SOCKET_PATH"),
		ApprovedClientSPIFFEID: os.Getenv("BACKEND_APPROVED_CLIENT_SPIFFEID"),
		Name:                   os.Getenv("BACKEND_NAME"),
		Infra:                  os.Getenv("BACKEND_INFRA"),
		Port:                   os.Getenv("BACKEND_PORT"),
	}

	// Create a `workloadapi.X509Source`
	source, err := workloadapi.NewX509Source(ctx,
		workloadapi.WithClientOptions(workloadapi.WithAddr(config.SocketPath), workloadapi.WithLogger(logger.Std)))
	if err != nil {
		return fmt.Errorf("unable to create X509Source: %w", err)
	}
	defer source.Close()

	svid, err := source.GetX509SVID()
	if err != nil {
		return fmt.Errorf("unable to get X509SVID: %w", err)
	}
	fmt.Println(svid.ID.String())

	clientID := spiffeid.RequireFromString(config.ApprovedClientSPIFFEID)

	tlsConfig := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeID(clientID))
	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", config.Port),
		TLSConfig:         tlsConfig,
		ReadHeaderTimeout: time.Second * 10,
	}

	// Set up a `/` resource handler
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Request received - Serving Response")

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
