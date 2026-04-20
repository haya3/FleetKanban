//go:build windows

package winapi

import (
	"bytes"
	"testing"
)

func TestDPAPI_RoundTrip(t *testing.T) {
	plain := []byte("ghp_exampletoken_with_symbols_@#$%!_end")
	ct, err := ProtectBytes(plain)
	if err != nil {
		t.Fatalf("ProtectBytes: %v", err)
	}
	if bytes.Equal(ct, plain) {
		t.Fatal("ciphertext equals plaintext — encryption did not happen")
	}
	pt, err := UnprotectBytes(ct)
	if err != nil {
		t.Fatalf("UnprotectBytes: %v", err)
	}
	if !bytes.Equal(pt, plain) {
		t.Fatalf("roundtrip mismatch: %q vs %q", pt, plain)
	}
}

func TestDPAPI_Empty(t *testing.T) {
	ct, err := ProtectBytes(nil)
	if err != nil || ct != nil {
		t.Fatalf("empty protect: ct=%v err=%v", ct, err)
	}
	pt, err := UnprotectBytes(nil)
	if err != nil || pt != nil {
		t.Fatalf("empty unprotect: pt=%v err=%v", pt, err)
	}
}

func TestDPAPI_TamperedCiphertextFails(t *testing.T) {
	ct, err := ProtectBytes([]byte("secret"))
	if err != nil {
		t.Fatalf("ProtectBytes: %v", err)
	}
	// Flip a byte in the middle; DPAPI should reject.
	mid := len(ct) / 2
	ct[mid] ^= 0xff
	if _, err := UnprotectBytes(ct); err == nil {
		t.Fatal("expected UnprotectBytes to reject tampered ciphertext")
	}
}
