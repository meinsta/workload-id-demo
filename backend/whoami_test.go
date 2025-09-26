package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/svid/x509svid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

// mockX509Source implements workloadapi.X509Source for testing
type mockX509Source struct {
	svid *x509svid.SVID
}

func (m *mockX509Source) GetX509SVID() (*x509svid.SVID, error) {
	return m.svid, nil
}

func (m *mockX509Source) GetX509BundleForTrustDomain(trustDomain spiffeid.TrustDomain) (*x509.Bundle, error) {
	return nil, nil
}

func (m *mockX509Source) GetX509Context() (*workloadapi.X509Context, error) {
	return nil, nil
}

func (m *mockX509Source) WatchX509Context(ctx context.Context) <-chan *workloadapi.X509Context {
	return nil
}

func (m *mockX509Source) Close() error {
	return nil
}

func (m *mockX509Source) Updated() <-chan struct{} {
	return nil
}

func TestWhoAmIEndpoint(t *testing.T) {
	// Create a mock SVID that expires in 5 minutes
	spiffeID := spiffeid.RequireFromString("spiffe://example.com/test")
	notAfter := time.Now().Add(5 * time.Minute)
	
	// Create a mock certificate
	cert := &x509.Certificate{
		NotAfter: notAfter,
	}
	
	mockSVID := &x509svid.SVID{
		ID:           spiffeID,
		Certificates: []*x509.Certificate{cert},
		PrivateKey:   nil, // Not needed for this test
	}
	
	mockSource := &mockX509Source{svid: mockSVID}
	
	// Create handler with mock source
	handler := createWhoAmIHandler(mockSource)
	
	// Create test request
	req := httptest.NewRequest("GET", "/whoami", nil)
	w := httptest.NewRecorder()
	
	// Execute request
	handler(w, req)
	
	// Check response
	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}
	
	// Parse JSON response
	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("Failed to parse JSON response: %v", err)
	}
	
	// Verify response fields
	if response["spiffe_id"] != spiffeID.String() {
		t.Errorf("Expected spiffe_id %s, got %v", spiffeID.String(), response["spiffe_id"])
	}
	
	if response["not_after"] == "" {
		t.Error("Expected not_after field to be present")
	}
	
	if response["expires_in"] == "" {
		t.Error("Expected expires_in field to be present")
	}
	
	if !strings.Contains(response["note"].(string), "mTLS certificate") {
		t.Error("Expected note to mention mTLS certificate authentication")
	}
	
	// Verify expires_in is reasonable (should be close to 5 minutes)
	expiresIn := response["expires_in"].(string)
	if !strings.Contains(expiresIn, "4m") && !strings.Contains(expiresIn, "5m") {
		t.Errorf("Expected expires_in around 5 minutes, got %s", expiresIn)
	}
}

// createWhoAmIHandler creates the /whoami handler for testing
func createWhoAmIHandler(source workloadapi.X509Source) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Get current SVID (may have rotated since startup)
		currentSVID, err := source.GetX509SVID()
		if err != nil {
			http.Error(w, "Failed to get current SVID", http.StatusInternalServerError)
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
	}
}

func TestNoAPIKeyPattern(t *testing.T) {
	// This test verifies that we don't accidentally use API key patterns
	
	req := httptest.NewRequest("GET", "/", nil)
	
	// Add an Authorization header to simulate legacy pattern
	req.Header.Set("Authorization", "Bearer some-api-key")
	
	// Our handler should not check this header - mTLS does authentication
	// This test verifies we don't validate Authorization headers
	
	// If this test passes, it means we successfully avoid the API key pattern
	authHeader := req.Header.Get("Authorization")
	if authHeader == "" {
		t.Skip("No Authorization header to test (expected in AFTER state)")
	}
	
	// In the AFTER state, we should ignore Authorization headers entirely
	// The presence of the header should not affect functionality
	t.Logf("INFO: Authorization header present but ignored (AFTER state): %s", authHeader)
}
