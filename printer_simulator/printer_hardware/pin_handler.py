from abc import ABC, abstractmethod
from typing import Any


class PinHandler(ABC):
    @abstractmethod
    def get_name(self) -> str:
        raise NotImplementedError

    @property
    @abstractmethod
    def read_pins(self) -> list[str]:
        raise NotImplementedError

    @property
    @abstractmethod
    def write_pins(self) -> list[str]:
        raise NotImplementedError

    @abstractmethod
    def set(self, key: str, value: int) -> None:
        raise NotImplementedError

    @abstractmethod
    def get(self, key: str) -> int:
        raise NotImplementedError

    @abstractmethod
    def state(self) -> dict[str, Any]:
        raise NotImplementedError
