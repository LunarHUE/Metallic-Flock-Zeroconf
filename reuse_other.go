//go:build !unix

package zeroconf

import "syscall"

// reuseControl is a no-op on non-Unix platforms (e.g. Windows), which lack
// SO_REUSEPORT. Preserves cross-platform builds without changing bind behavior.
func reuseControl(network, address string, c syscall.RawConn) error {
	return nil
}
