__all__ = [
    "ShiftStatus"
]

from enum import Enum


class ShiftStatus(Enum):
    CLOSED = 1
    OPENED = 2
    SIGNED_IN = 3
    SIGNED_OUT = 4