"""
This module provides utility functions for interfacing with foreign languages,
such as type conversions that may not normally apply to Python.

Numeric type names are borrowed from Rust, which has a concise and uniform
convention. For example:

- i32 = 32-bit signed integer
- u32 = 32-bit unsigned integer
- f32 = 32-bit float
"""

import struct


def i64_to_f64(value: int) -> float:
    """
    Convert a 64-bit signed integer to a 64-bit float.

    :param value: Number to convert.
    :return: Converted number.
    """
    return struct.unpack('d', struct.pack('q', int(value)))[0]


def f64_to_i64(value: float) -> int:
    """
    Convert a 64-bit float to a 64-bit signed integer.

    :param value: Number to convert.
    :return: Converted number.
    """
    return struct.unpack('q', struct.pack('d', float(value)))[0]
