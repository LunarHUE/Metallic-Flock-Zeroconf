//go:build unix

package zeroconf

import (
	"syscall"

	"golang.org/x/sys/unix"
)

// reuseControl sets SO_REUSEADDR and SO_REUSEPORT on the socket before bind so
// that multiple mDNS responders (e.g. this stack alongside avahi-daemon) can
// share UDP port 5353, per RFC 6762 section 15.1.
func reuseControl(network, address string, c syscall.RawConn) error {
	var sockErr error
	if err := c.Control(func(fd uintptr) {
		if sockErr = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_REUSEADDR, 1); sockErr != nil {
			return
		}
		sockErr = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_REUSEPORT, 1)
	}); err != nil {
		return err
	}
	return sockErr
}
