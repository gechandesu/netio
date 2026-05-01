module netio

// The socket address family type.
// See [address_families(7)](https://www.man7.org/linux/man-pages/man7/address_families.7.html).
pub type AddrFamily = int

// The protocol number.
// See [protocols(5)](https://man7.org/linux/man-pages/man5/protocols.5.html).
pub type Protocol = int

// The socket type.
pub type SocketType = int

// The socket level type.
pub type SocketLevel = int

// The socket option type.
pub type SocketOption = int

// Flag type for `addr_info()`.
// See [getaddrinfo(3)](https://man7.org/linux/man-pages/man3/getaddrinfo.3.html) for details.
pub type AddrInfoFlag = int

// Flag type for `name_info()`.
// See [getnameinfo(3)](https://man7.org/linux/man-pages/man3/getnameinfo.3.html) for details.
pub type NameInfoFlag = int

// Type for recv, recvfrom, recvmsg, send, sendto, sendmsg flags.
pub type MsgFlag = int
