module netio

import os

#include <sys/socket.h>
#include <netinet/in.h>

fn C.socket(i32, i32, i32) i32
fn C.bind(i32, voidptr, i32) i32
fn C.connect(i32, voidptr, i32) i32
fn C.listen(i32, i32) i32
fn C.accept(i32, voidptr, voidptr) i32
fn C.shutdown(i32, i32) i32
fn C.close(i32) i32
fn C.setsockopt(i32, i32, i32, voidptr, i32) i32
fn C.getsockopt(i32, i32, i32, voidptr, voidptr) i32
fn C.recv(i32, voidptr, usize, i32) i32
fn C.recvfrom(i32, voidptr, usize, i32, voidptr, i32) i32
fn C.send(i32, voidptr, usize, i32) i32
fn C.sendto(i32, voidptr, usize, i32, voidptr, i32) i32

pub struct Socket {
pub:
	fd int = -1
}

// Socket.new creates the new socket.
// See [socket(7)](https://www.man7.org/linux/man-pages/man7/socket.7.html) and
// [socket(3)](https://man7.org/linux/man-pages/man3/socket.3p.html) for details.
pub fn Socket.new(domain AddrFamily, st SocketType, proto Protocol) !Socket {
	fd := C.socket(i32(domain), i32(st), i32(proto))
	if fd == -1 {
		return os.last_error()
	}
	return Socket{
		fd: fd
	}
}

// type reports the actual socket type. Look for `sock_*` constants.
pub fn (s Socket) type() !SocketType {
	return s.get_option[SocketType](sol_socket, so_type)!
}

// Socket shutdown modes. See [shutdown(3p)](https://man7.org/linux/man-pages/man3/shutdown.3p.html) for details.
pub enum Shutdown {
	read
	write
	read_and_write
}

// connect connects a socket. See [connect(3p)](https://man7.org/linux/man-pages/man3/connect.3p.html) for details.
pub fn (s Socket) connect(addr SocketAddr) ! {
	if C.connect(s.fd, addr.ptr(), addr.size()) == -1 {
		return os.last_error()
	}
}

// bind binds a name to a socket. See [bind(3p)](https://man7.org/linux/man-pages/man3/bind.3p.html) for details.
pub fn (s Socket) bind(addr SocketAddr) ! {
	if C.bind(s.fd, addr.ptr(), addr.size()) == -1 {
		return os.last_error()
	}
}

// listen starts listening for socket connections and limit the queue of incoming connections.
// See [listen(3p)](https://man7.org/linux/man-pages/man3/listen.3p.html) for details.
pub fn (s Socket) listen(backlog int) ! {
	if C.listen(s.fd, backlog) == -1 {
		return os.last_error()
	}
}

// accept accepts a new connection on a socket.
// The return values are the new socket connected to remote and the remote socket address.
// See [accept(3p)](https://man7.org/linux/man-pages/man3/accept.3p.html) for details.
pub fn (s Socket) accept() !(Socket, SocketAddr) {
	mut sock_addr_storage := &C.sockaddr_storage{}
	mut sock_addr_len := sizeof(C.sockaddr_storage)
	fd := C.accept(s.fd, sock_addr_storage, &sock_addr_len)
	if fd == -1 {
		return os.last_error()
	}
	sock := Socket{
		fd: fd
	}
	sock_addr := unsafe {
		SocketAddr.from_ptr(sock_addr_storage, sock_addr_len)!
	}
	return sock, sock_addr
}

fn (s Socket) set_option_raw(level SocketLevel, option SocketOption, value voidptr) ! {
	if C.setsockopt(s.fd, i32(level), i32(option), value, sizeof(value)) == -1 {
		return os.last_error()
	}
}

// set_option sets the socket option. See [socket(7)](https://man7.org/linux/man-pages/man7/socket.7.html)
// and [setsockopt(3p)](https://man7.org/linux/man-pages/man3/setsockopt.3p.html) for details.
pub fn (s Socket) set_option[T](level SocketLevel, option SocketOption, value T) ! {
	s.set_option_raw(level, option, &value)!
}

fn (s Socket) get_option_raw(level SocketLevel, option SocketOption, mut value voidptr, mut size voidptr) ! {
	if C.getsockopt(s.fd, i32(level), i32(option), value, size) == -1 {
		return os.last_error()
	}
}

// get_option gets the socket option. See [socket(7)](https://man7.org/linux/man-pages/man7/socket.7.html)
// and [getsockopt(3p)](https://man7.org/linux/man-pages/man3/getsockopt.3p.html) for details.
// Example:
// ```v
// import netio
// mut socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
// socket.set_option(netio.sol_socket, netio.so_reuseaddr, 1)!
// assert socket.get_option[int](netio.sol_socket, netio.so_reuseaddr)! == 1
// ```
pub fn (s Socket) get_option[T](level SocketLevel, option SocketOption) !T {
	mut result := T{}
	mut size := sizeof(result)
	s.get_option_raw(level, option, mut &result, mut &size)!
	return result
}

// recv receives a message from a connected socket.
// See [recv(3p)](https://man7.org/linux/man-pages/man3/recv.3p.html) for details.
pub fn (s Socket) recv(mut buf []u8, flags MsgFlag) !int {
	r := C.recv(s.fd, buf.data, buf.len, flags)
	if r == -1 {
		return os.last_error()
	}
	return r
}

// recv_from receives a message from a connected socket and returns the number of bytes
// read and the remote peer address.
// See [recvfrom(3p)](https://man7.org/linux/man-pages/man3/recvfrom.3p.html) for details.
pub fn (s Socket) recv_from(mut buf []u8, flags MsgFlag) !(int, SocketAddr) {
	mut sock_addr_storage := &C.sockaddr_storage{}
	mut sock_addr_len := sizeof(C.sockaddr_storage)
	r := C.recvfrom(s.fd, buf.data, buf.len, flags, sock_addr_storage, sock_addr_len)
	if r == -1 {
		return os.last_error()
	}
	return r, unsafe { SocketAddr.from_ptr(sock_addr_storage, sock_addr_len)! }
}

// send sends a message on socket.
// See [send(3p)](https://man7.org/linux/man-pages/man3/send.3p.html) for details.
pub fn (s Socket) send(buf []u8, flags MsgFlag) !int {
	r := C.send(s.fd, buf.data, buf.len, flags)
	if r == -1 {
		return os.last_error()
	}
	return r
}

// send_to sends a message on socket using the dst socket address as destination
// instead of the socket peer address.
// See [sendto(3p)](https://man7.org/linux/man-pages/man3/sendto.3p.html) for details.
pub fn (s Socket) send_to(buf []u8, dst SocketAddr, flags MsgFlag) !int {
	r := C.sendto(s.fd, buf.data, buf.len, flags, dst.ptr(), dst.size())
	if r == -1 {
		return os.last_error()
	}
	return r
}

// shutdown shut downs socket send and receive operations.
// See [shutodwn(3p)](https://man7.org/linux/man-pages/man3/shutdown.3p.html) for details.
pub fn (s Socket) shutdown(how Shutdown) ! {
	if C.shutdown(s.fd, i32(how)) == -1 {
		return os.last_error()
	}
}

// close closes the socket.
// See [close(3p)](https://man7.org/linux/man-pages/man3/close.3p.html) for details.
pub fn (s Socket) close() ! {
	if C.close(s.fd) == -1 {
		return os.last_error()
	}
}
