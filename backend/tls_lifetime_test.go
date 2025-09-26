package main

import (
	"crypto/x509"
	"testing"
	"time"

	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/svid/x509svid"
)

func TestTLSLifetimeLogging(t *testing.T) {
	// Test certificate lifetime calculations and logging
	
	testCases := []struct {
		name        string
		expiresIn   time.Duration
		expectWarn  bool
		description string
	}{
		{
			name:        "fresh_certificate",
			expiresIn:   10 * time.Minute,
			expectWarn:  false,
			description: "Certificate with 10 minutes remaining should not warn",
		},
		{
			name:        "near_expiry",
			expiresIn:   30 * time.Second,
			expectWarn:  true,
			description: "Certificate with 30 seconds remaining should warn",
		},
		{
			name:        "very_fresh",
			expiresIn:   1 * time.Hour,
			expectWarn:  false,
			description: "Certificate with 1 hour remaining should not warn",
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create mock certificate with specific expiry
			spiffeID := spiffeid.RequireFromString("spiffe://example.com/test")
			notAfter := time.Now().Add(tc.expiresIn)
			
			cert := &x509.Certificate{
				NotAfter: notAfter,
			}
			
			svid := &x509svid.SVID{
				ID:           spiffeID,
				Certificates: []*x509.Certificate{cert},
				PrivateKey:   nil,
			}
			
			// Calculate remaining lifetime
			remainingLifetime := time.Until(svid.Certificates[0].NotAfter)
			
			// Verify lifetime calculation is approximately correct
			expectedLifetime := tc.expiresIn
			tolerance := 1 * time.Second
			
			if remainingLifetime < expectedLifetime-tolerance || 
			   remainingLifetime > expectedLifetime+tolerance {
				t.Errorf("Expected remaining lifetime around %v, got %v", 
					expectedLifetime, remainingLifetime)
			}
			
			// Test warning logic
			shouldWarn := remainingLifetime < 2*time.Minute
			if shouldWarn != tc.expectWarn {
				t.Errorf("Expected warn=%v for %v remaining, got warn=%v", 
					tc.expectWarn, remainingLifetime, shouldWarn)
			}
			
			t.Logf("%s: SPIFFE ID=%s, expires in %v, warn=%v", 
				tc.description, svid.ID, remainingLifetime.Truncate(time.Second), shouldWarn)
		})
	}
}

func TestAutomaticRotationBenefits(t *testing.T) {
	// This test documents the benefits of automatic rotation vs manual API key management
	
	t.Log("=== BEFORE (API Keys) ===")
	t.Log("❌ Manual rotation required")
	t.Log("❌ Risk of forgotten updates")
	t.Log("❌ Shared secrets in environment")
	t.Log("❌ No cryptographic binding")
	
	t.Log("")
	t.Log("=== AFTER (Teleport Workload ID) ===")
	t.Log("✅ Automatic rotation via tbot")
	t.Log("✅ No manual intervention needed")
	t.Log("✅ No secrets in environment")
	t.Log("✅ Cryptographic identity binding")
	
	// Mock a certificate rotation scenario
	oldExpiry := time.Now().Add(1 * time.Minute)  // Soon to expire
	newExpiry := time.Now().Add(10 * time.Minute) // Fresh certificate
	
	oldLifetime := time.Until(oldExpiry)
	newLifetime := time.Until(newExpiry)
	
	t.Logf("Certificate rotation: %v → %v", 
		oldLifetime.Truncate(time.Second),
		newLifetime.Truncate(time.Second))
	
	if newLifetime <= oldLifetime {
		t.Error("Expected new certificate to have longer lifetime")
	}
}

func TestCertificateLifetimeFormatting(t *testing.T) {
	// Test various lifetime formatting scenarios
	
	testCases := []struct {
		duration time.Duration
		expected string
	}{
		{5 * time.Minute, "5m0s"},
		{90 * time.Second, "1m30s"},
		{10 * time.Hour, "10h0m0s"},
	}
	
	for _, tc := range testCases {
		formatted := tc.duration.Truncate(time.Second).String()
		if formatted != tc.expected {
			t.Errorf("Expected %s, got %s", tc.expected, formatted)
		}
		
		t.Logf("Duration %v formats as: %s", tc.duration, formatted)
	}
}

func TestSVIDIdentityValidation(t *testing.T) {
	// Test SPIFFE ID validation for the AFTER state
	
	validIDs := []string{
		"spiffe://example.com/apps/backend",
		"spiffe://cluster.local/ns/default/sa/backend",
		"spiffe://mwidemo.cloud.gravitational.io/apps/w2w-demo/backend-1",
	}
	
	for _, idStr := range validIDs {
		spiffeID, err := spiffeid.FromString(idStr)
		if err != nil {
			t.Errorf("Expected valid SPIFFE ID %s, got error: %v", idStr, err)
			continue
		}
		
		// Verify the ID is well-formed
		if spiffeID.String() != idStr {
			t.Errorf("SPIFFE ID round-trip failed: %s != %s", spiffeID.String(), idStr)
		}
		
		t.Logf("✅ Valid SPIFFE ID: %s", spiffeID.String())
	}
	
	// Test that we can identify the trust domain
	exampleID := spiffeid.RequireFromString("spiffe://example.com/apps/backend")
	expectedTrustDomain := "example.com"
	
	if exampleID.TrustDomain().String() != expectedTrustDomain {
		t.Errorf("Expected trust domain %s, got %s", 
			expectedTrustDomain, exampleID.TrustDomain().String())
	}
}
