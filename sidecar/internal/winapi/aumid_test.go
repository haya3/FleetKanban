//go:build windows

package winapi

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSetAppUserModelID(t *testing.T) {
	// Sets a valid AUMID for this test process.
	require.NoError(t, SetAppUserModelID("com.fleetkanban.test"))
}

func TestSetAppUserModelID_RoundTrip(t *testing.T) {
	// Subsequent calls with a different ID must also succeed; the OS
	// replaces the previous value without error.
	require.NoError(t, SetAppUserModelID("com.fleetkanban.test.alpha"))
	require.NoError(t, SetAppUserModelID("com.fleetkanban.test.beta"))
}

func TestSetAppUserModelID_Empty(t *testing.T) {
	// Empty string must be rejected before any Win32 call is made.
	err := SetAppUserModelID("")
	assert.Error(t, err, "empty AUMID must return an error")
}
