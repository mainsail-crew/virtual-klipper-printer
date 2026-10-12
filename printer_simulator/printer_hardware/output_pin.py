from .pin_handler import PinHandler


class OutputPin(PinHandler):
    def __init__(self, name: str, pin: str, initial_value: int = 0, verbose: bool = False):
        self.name = name
        self.pin = pin
        self.value = initial_value
        self.verbose = verbose

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return []

    @property
    def write_pins(self) -> list[str]:
        return [self.pin]

    def set(self, key: str, value: int) -> None:
        if key == self.pin:
            self.value = value
            if self.verbose:
                print(f"[{self.name}] set pin {key} to {value}")
        else:
            print(f"[{self.name}] unknown pin: {key}")

    def get(self, key: str) -> int:
        print(f"[{self.name}] cannot read pin {key} - pin is write-only")
        return 0

    def state(self) -> dict[str, int | str]:
        return {
            "type": "output_pin",
            "pin": self.pin,
            "value": self.value,
        }
