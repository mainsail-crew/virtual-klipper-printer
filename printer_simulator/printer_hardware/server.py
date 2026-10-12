import os
import socket
import threading
import time

from .pin_handler import PinHandler
from .state_io import STATE_FILE_PATH, atomic_write_json, build_printer_state


class FakeHardwareServer:
    def __init__(
        self,
        hardware_components: list[PinHandler],
        socket_path: str = "/tmp/printer_hook.sock",
        state_file_path: str = STATE_FILE_PATH,
        min_state_write_interval: float = 0.2,
    ):
        self.hardware_components = hardware_components
        self.read_mapping: dict[str, PinHandler] = {}
        self.write_mapping: dict[str, PinHandler] = {}
        for component in hardware_components:
            for pin in component.read_pins:
                if pin in self.read_mapping:
                    raise ValueError(
                        f"Pin {pin} is already assigned to another component for reading!"
                    )
                self.read_mapping[pin] = component
            for pin in component.write_pins:
                if pin in self.write_mapping:
                    raise ValueError(
                        f"Pin {pin} is already assigned to another component for writing!"
                    )
                self.write_mapping[pin] = component
        self.socket_path = socket_path
        self.lock = threading.Lock()
        self.state_file_path = state_file_path
        self.min_state_write_interval = min_state_write_interval
        self._last_state_write_monotonic = 0.0

    def _dump_state(self, force: bool = False) -> None:
        current = time.monotonic()
        if (
            not force
            and (current - self._last_state_write_monotonic) < self.min_state_write_interval
        ):
            return
        atomic_write_json(self.state_file_path, build_printer_state(self.hardware_components))
        self._last_state_write_monotonic = current

    def set(self, key: str, value: int) -> None:
        """Set the value of a writable hardware pin.

        Parameters:
            key: The name or identifier of the hardware pin to update.
            value: The integer value to write to the specified pin.
        """
        with self.lock:
            if key in self.write_mapping:
                self.write_mapping[key].set(key, value)
                self._dump_state()
            else:
                print(f"[server] set unknown key: {key}={value}")

    def get(self, key: str) -> int:
        with self.lock:
            if key in self.read_mapping:
                value = self.read_mapping[key].get(key)
                self._dump_state()
                return value
            print(f"[server] get unknown key: {key}")
            return 0

    def _handle_client(self, conn):
        try:
            data = conn.recv(64).decode().strip()
            parts = data.split()

            if parts[0] == "GET" and len(parts) == 2:
                value = self.get(parts[1])
                conn.send(f"{value}\n".encode())

            elif parts[0] == "SET" and len(parts) == 3:
                key, value = parts[1], int(parts[2])
                self.set(key, value)
                conn.send(b"OK\n")

            else:
                conn.send(b"ERR malformed command\n")
        except Exception as e:
            print(f"[server] error: {e}")
        finally:
            conn.close()

    def run(self):
        if os.path.exists(self.socket_path):
            os.remove(self.socket_path)

        self._dump_state(force=True)
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(self.socket_path)
        server.listen(5)
        print(f"[server] listening on {self.socket_path}")

        while True:
            conn, _ = server.accept()
            threading.Thread(target=self._handle_client, args=(conn,), daemon=True).start()
