package zeroconf

import "testing"

// TestNewConn4ReusePort verifies that two IPv4 mDNS sockets can bind port 5353
// concurrently — i.e. SO_REUSEADDR/SO_REUSEPORT are set and neither bind fails
// with EADDRINUSE. This mirrors coexisting with another responder (avahi-daemon)
// on the same port, per RFC 6762 section 15.1.
func TestNewConn4ReusePort(t *testing.T) {
	c1, err := newConn4()
	if err != nil {
		t.Fatalf("first newConn4() failed: %v", err)
	}
	defer c1.Close()

	c2, err := newConn4()
	if err != nil {
		t.Fatalf("second newConn4() failed (port not reusable?): %v", err)
	}
	defer c2.Close()
}

// TestNewConn6ReusePort is the IPv6 counterpart of TestNewConn4ReusePort.
func TestNewConn6ReusePort(t *testing.T) {
	c1, err := newConn6()
	if err != nil {
		t.Fatalf("first newConn6() failed: %v", err)
	}
	defer c1.Close()

	c2, err := newConn6()
	if err != nil {
		t.Fatalf("second newConn6() failed (port not reusable?): %v", err)
	}
	defer c2.Close()
}
