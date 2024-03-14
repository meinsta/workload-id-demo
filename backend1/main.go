package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

// Workload API socket path
const socketPath = "unix:///etc/tbot/demo-backend-1.sock"

func main() {
	log.Println("Server is starting...")
	if err := run(context.Background()); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func run(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// Create a `workloadapi.X509Source`
	source, err := workloadapi.NewX509Source(ctx, workloadapi.WithClientOptions(workloadapi.WithAddr(socketPath)))
	if err != nil {
		return fmt.Errorf("unable to create X509Source: %w", err)
	}
	defer source.Close()

	svid, err := source.GetX509SVID()
	if err != nil {
		return fmt.Errorf("unable to get X509SVID: %w", err)
	}
	fmt.Println(svid.ID.String())

	clientID := spiffeid.RequireFromString("spiffe://teleport-ent-15-workload.asteroid.earth/client")

	tlsConfig := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeID(clientID))
	server := &http.Server{
		Addr:              ":8443",
		TLSConfig:         tlsConfig,
		ReadHeaderTimeout: time.Second * 10,
	}

	// Set up a `/` resource handler
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Request received - Serving Response")

		data := make(map[string]string)
		data["svid"] = svid.ID.String()
		data["name"] = "Backend 1"
		data["infra"] = "VM"

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(data)
	})

	log.Printf("Server listening on %s", server.Addr)
	if err := server.ListenAndServeTLS("", ""); err != nil {
		return fmt.Errorf("failed to serve: %w", err)
	}

	return nil
}
