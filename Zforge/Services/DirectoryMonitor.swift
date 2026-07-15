import Darwin
import Foundation

@MainActor
final class DirectoryMonitor {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceTask: Task<Void, Never>?

    func watch(_ url: URL, onChange: @escaping @MainActor () -> Void) {
        stop()
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend, .attrib, .link, .revoke],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                onChange()
            }
        }
        source.setCancelHandler { [fileDescriptor] in
            if fileDescriptor >= 0 { close(fileDescriptor) }
        }
        self.source = source
        source.resume()
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    deinit {
        source?.cancel()
    }
}
