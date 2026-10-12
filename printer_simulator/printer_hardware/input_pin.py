from .pin_handler import PinHandler


class InputPin(PinHandler):
    def __init__(self, name: str, pin: str, initial_value: int = 0):
        self.name = name
        self.pin = pin
        self.value = initial_value

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return [self.pin]

    @property
    def write_pins(self) -> list[str]:
        return []

    def set(self, key: str, value: int) -> None:
        print(f"[{self.name}] cannot set pin {key} to {value} - pin is read-only")

    def get(self, key: str) -> int:
        if key == self.pin:
            return self.value
        print(f"[{self.name}] unknown pin: {key}")
        return 0

    def state(self) -> dict[str, int | str]:
        return {
            "type": "input_pin",
            "pin": self.pin,
            "value": self.value,
        }
