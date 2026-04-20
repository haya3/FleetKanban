//go:build windows

package winapi

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestBackdropType_Values(t *testing.T) {
	// Verify that the enum constants match the DWMSBT_* values from dwmapi.h.
	tests := []struct {
		name string
		got  BackdropType
		want BackdropType
	}{
		{"Auto", BackdropAuto, BackdropType(0)},
		{"None", BackdropNone, BackdropType(1)},
		{"Mica", BackdropMica, BackdropType(2)},
		{"Acrylic", BackdropAcrylic, BackdropType(3)},
		{"MicaAlt", BackdropMicaAlt, BackdropType(4)},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.want, tc.got)
		})
	}
}

func TestDWMConstants(t *testing.T) {
	// Confirm the unexported attribute IDs match the Windows SDK values.
	assert.Equal(t, 20, dwmwaUseImmersiveDarkMode)
	assert.Equal(t, 38, dwmwaSystemBackdropType)
}

func TestApplyBackdrop_InvalidHandle(t *testing.T) {
	// HWND(0) is always invalid; DwmSetWindowAttribute must return an error.
	err := ApplyBackdrop(0, BackdropMica)
	assert.Error(t, err, "invalid HWND must produce an error")
}

func TestSetImmersiveDarkMode_InvalidHandle(t *testing.T) {
	// Same: null HWND must be rejected by DWM.
	err := SetImmersiveDarkMode(0, true)
	assert.Error(t, err, "invalid HWND must produce an error")
}
