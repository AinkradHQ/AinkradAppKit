import Foundation

/// Where the external-ingress socket lives.
///
/// **A contract, not an implementation detail.** The host binds this path and
/// `ainkrad notify` derives it independently — there is no discovery step and
/// no handshake — so changing it silently breaks every hook and script already
/// installed on a machine. It is defined once, here, in the module both sides
/// already depend on, precisely so the two cannot drift.
public enum SignalSocketPath {
    /// `~/Library/Application Support/<bundleID>/signal.sock`.
    ///
    /// Beside the event store rather than in `/tmp`: `/tmp` is world-writable,
    /// so another local user could pre-create the path and receive
    /// notifications intended for this one. The directory here is owned by the
    /// user, and `SignalSocketServer` narrows the socket itself to 0600 at
    /// bind time.
    ///
    /// Derived from the bundle id rather than from the user's chosen Home
    /// folder. The Home folder moves — that is the point of it — and a socket
    /// that moved with it would leave the CLI unable to find the host without
    /// reading the host's configuration first.
    public static func `default`(bundleID: String = "com.ainkrad.app") -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("signal.sock")
    }

    /// `sockaddr_un.sun_path` is a fixed-size C array (~104 bytes on Darwin).
    /// Exposed so both ends can refuse an unrepresentable path rather than let
    /// `strncpy` truncate one — a silently shortened path binds a socket
    /// nobody can find.
    public static var maxPathBytes: Int { MemoryLayout.size(ofValue: sockaddr_un().sun_path) - 1 }
}

/// Connect, write, close. One newline-terminated JSON payload per connection.
///
/// Shared by the host's own tests and by `ainkrad notify`, so the CLI cannot
/// drift from what the server actually accepts.
public enum SignalSocketClient {
    public enum SendFailure: Error, Equatable, Sendable {
        case socketUnavailable(errno: Int32)
        /// Nobody is listening. **The ordinary case, not an exceptional one:**
        /// the host simply is not running, and `ainkrad notify` turns this into
        /// exit 0 with a warning on stderr.
        case notListening(errno: Int32)
        case writeFailed(errno: Int32)
        case pathTooLong(length: Int)
    }

    public static func send(_ payload: Data, to url: URL) throws {
        let path = url.path
        guard path.utf8.count <= SignalSocketPath.maxPathBytes else {
            throw SendFailure.pathTooLong(length: path.utf8.count)
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw SendFailure.socketUnavailable(errno: errno) }
        defer { close(fd) }

        // Writing to a socket the peer has already closed raises SIGPIPE,
        // whose default disposition TERMINATES the process. Not hypothetical:
        // the server closes the connection as soon as it knows a payload is
        // over the 8 KB cap, so an oversized `ainkrad notify` would be killed
        // by a signal mid-write — a notification tool taking down the script
        // that called it, which is exactly what this must never do.
        //
        // SO_NOSIGPIPE makes it an ordinary EPIPE from `write`, reported below
        // as `.writeFailed`.
        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        _ = withUnsafeMutablePointer(to: &address.sun_path) { destination in
            path.withCString { source in
                strncpy(UnsafeMutableRawPointer(destination).assumingMemoryBound(to: CChar.self),
                        source, capacity - 1)
            }
        }

        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let connected = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, size) }
        }
        guard connected == 0 else { throw SendFailure.notListening(errno: errno) }

        guard !payload.isEmpty else { return }
        try payload.withUnsafeBytes { raw in
            var sent = 0
            while sent < raw.count {
                let wrote = write(fd, raw.baseAddress!.advanced(by: sent), raw.count - sent)
                if wrote <= 0 { throw SendFailure.writeFailed(errno: errno) }
                sent += wrote
            }
        }
    }
}
