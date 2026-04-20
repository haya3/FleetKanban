//go:build windows

package app

import "testing"

func TestIsWSLPath(t *testing.T) {
	cases := []struct {
		in   string
		want bool
	}{
		{`\\wsl$\Ubuntu\home\user\repo`, true},
		{`\\wsl.localhost\Ubuntu\home\user\repo`, true},
		{`\\WSL$\Ubuntu\x`, true},
		{`//wsl$/Ubuntu/x`, true},
		{`C:\Users\x\repo`, false},
		{`\\server\share\repo`, false},
		{``, false},
	}
	for _, c := range cases {
		if got := isWSLPath(c.in); got != c.want {
			t.Errorf("isWSLPath(%q) = %v, want %v", c.in, got, c.want)
		}
	}
}
