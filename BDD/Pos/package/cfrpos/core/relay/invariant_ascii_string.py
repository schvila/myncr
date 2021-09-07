class InvariantAsciiString:
    def __init__(self, value=''):
        self.value = str(value).lower()

    def __lt__(self, other):
        return other is not None \
                and isinstance(other, InvariantAsciiString) \
                and self.value < other.value
