"""UVM-RAL-inspired register model with AXI4-Lite adaptation."""

from dataclasses import dataclass, field
from enum import Enum

from .axi4lite import AxiLiteOperation, AxiLiteTransaction

__all__ = [
    "AxiLiteRegisterAdapter",
    "FieldSpec",
    "Register",
    "RegisterAccess",
    "RegisterAdapter",
    "RegisterBlock",
    "RegisterError",
    "RegisterField",
    "RegisterPredictor",
    "RegisterSpec",
]


class RegisterError(AssertionError):
    """Raised for an invalid register operation or mirror mismatch."""


class RegisterAccess(str, Enum):
    RO = "ro"
    RW = "rw"
    WO = "wo"

    @property
    def readable(self):
        return self is not RegisterAccess.WO

    @property
    def writable(self):
        return self is not RegisterAccess.RO


@dataclass(frozen=True)
class FieldSpec:
    """Static description of one register field."""

    name: str
    lsb: int
    width: int
    reset: int = 0
    access: RegisterAccess = RegisterAccess.RW
    volatile: bool = False

    def __post_init__(self):
        if self.lsb < 0:
            raise ValueError("field lsb must be non-negative")
        if self.width <= 0:
            raise ValueError("field width must be positive")
        if not 0 <= self.reset < 1 << self.width:
            raise ValueError(f"field {self.name} reset value does not fit its width")
        object.__setattr__(self, "access", RegisterAccess(self.access))

    @property
    def mask(self):
        return ((1 << self.width) - 1) << self.lsb

    def extract(self, register_value):
        return (register_value & self.mask) >> self.lsb

    def insert(self, register_value, field_value):
        if not 0 <= field_value < 1 << self.width:
            raise ValueError(
                f"value {field_value:#x} does not fit {self.name}[{self.width - 1}:0]"
            )
        return (register_value & ~self.mask) | (field_value << self.lsb)


@dataclass(frozen=True)
class RegisterSpec:
    """Static description of one addressable register."""

    name: str
    address: int
    fields: tuple[FieldSpec, ...]
    width: int = 32

    def __post_init__(self):
        if self.address < 0:
            raise ValueError("register address must be non-negative")
        if self.width <= 0 or self.width % 8:
            raise ValueError("register width must be a positive whole number of bytes")
        occupied = 0
        names = set()
        for field_spec in self.fields:
            if field_spec.name in names:
                raise ValueError(
                    f"duplicate field {field_spec.name!r} in register {self.name}"
                )
            if field_spec.lsb + field_spec.width > self.width:
                raise ValueError(f"field {field_spec.name} exceeds register width")
            if occupied & field_spec.mask:
                raise ValueError(f"overlapping field {field_spec.name} in {self.name}")
            occupied |= field_spec.mask
            names.add(field_spec.name)

    @property
    def reset_value(self):
        value = 0
        for field_spec in self.fields:
            value = field_spec.insert(value, field_spec.reset)
        return value

    @property
    def readable_mask(self):
        return self._access_mask(readable=True)

    @property
    def writable_mask(self):
        return self._access_mask(readable=False)

    @property
    def compare_mask(self):
        return sum(
            field_spec.mask
            for field_spec in self.fields
            if field_spec.access.readable and not field_spec.volatile
        )

    def _access_mask(self, *, readable):
        return sum(
            field_spec.mask
            for field_spec in self.fields
            if (field_spec.access.readable if readable else field_spec.access.writable)
        )

    def field(self, name):
        for field_spec in self.fields:
            if field_spec.name == name:
                return field_spec
        raise KeyError(f"register {self.name} has no field {name!r}")


class RegisterAdapter:
    """Frontdoor transport interface used by a :class:`RegisterBlock`."""

    async def read(self, address):
        raise NotImplementedError

    async def write(self, address, data, strobe=None):
        raise NotImplementedError


class AxiLiteRegisterAdapter(RegisterAdapter):
    """Adapt an active AXI4-Lite agent or driver to register operations."""

    def __init__(self, axi):
        self.axi = axi

    async def read(self, address):
        return await self.axi.read(address)

    async def write(self, address, data, strobe=None):
        return await self.axi.write(address, data, strobe=strobe)


class RegisterField:
    """Runtime field handle bound to its parent register."""

    def __init__(self, register, spec):
        self.register = register
        self.spec = spec

    @property
    def mirrored_value(self):
        return self.spec.extract(self.register.mirrored_value)

    async def write(self, value):
        if not self.spec.access.writable:
            raise RegisterError(
                f"field {self.register.name}.{self.spec.name} is read-only"
            )
        register_value = self.spec.insert(self.register.mirrored_value, value)
        await self.register.write(register_value)

    async def read(self):
        if not self.spec.access.readable:
            raise RegisterError(
                f"field {self.register.name}.{self.spec.name} is write-only"
            )
        return self.spec.extract(await self.register.read())


class Register:
    """Runtime register with frontdoor access and mirrored state."""

    def __init__(self, block, spec):
        self.block = block
        self.spec = spec
        self.mirrored_value = spec.reset_value
        self.fields = {
            field_spec.name: RegisterField(self, field_spec)
            for field_spec in spec.fields
        }

    @property
    def name(self):
        return self.spec.name

    @property
    def address(self):
        return self.spec.address

    def field(self, name):
        try:
            return self.fields[name]
        except KeyError as error:
            raise KeyError(f"register {self.name} has no field {name!r}") from error

    def __getattr__(self, name):
        fields = self.__dict__.get("fields", {})
        if name in fields:
            return fields[name]
        raise AttributeError(name)

    def reset_mirror(self):
        self.mirrored_value = self.spec.reset_value

    def predict_read(self, value):
        mask = self.spec.readable_mask
        self.mirrored_value = (self.mirrored_value & ~mask) | (value & mask)

    def predict_write(self, value, strobe=None):
        byte_count = self.spec.width // 8
        if strobe is None:
            strobe = (1 << byte_count) - 1
        byte_mask = 0
        for byte_index in range(byte_count):
            if strobe & (1 << byte_index):
                byte_mask |= 0xFF << (8 * byte_index)
        mask = self.spec.writable_mask & byte_mask
        self.mirrored_value = (self.mirrored_value & ~mask) | (value & mask)

    def _require_adapter(self):
        if self.block.adapter is None:
            raise RegisterError(f"register block {self.block.name} has no adapter")
        return self.block.adapter

    async def write(self, value, strobe=None):
        if not self.spec.writable_mask:
            raise RegisterError(f"register {self.name} is read-only")
        await self._require_adapter().write(self.address, value, strobe)
        self.predict_write(value, strobe)

    async def read(self):
        if not self.spec.readable_mask:
            raise RegisterError(f"register {self.name} is write-only")
        value = await self._require_adapter().read(self.address)
        self.predict_read(value)
        return value

    async def mirror(self, check=True):
        """Read hardware, optionally comparing against the pre-read mirror."""
        expected = self.mirrored_value
        value = await self._require_adapter().read(self.address)
        mask = self.spec.compare_mask
        if check and (value & mask) != (expected & mask):
            raise RegisterError(
                f"register {self.name} ({self.address:#x}) mirror mismatch: "
                f"actual={value & mask:#010x}, expected={expected & mask:#010x}, "
                f"mask={mask:#010x}"
            )
        self.predict_read(value)
        return value


@dataclass
class RegisterBlock:
    """Collection of register specifications and mirrored runtime handles."""

    name: str
    specs: tuple[RegisterSpec, ...]
    adapter: RegisterAdapter | None = None
    registers: dict[str, Register] = field(init=False)
    _address_map: dict[int, Register] = field(init=False)

    def __post_init__(self):
        self.registers = {}
        self._address_map = {}
        for spec in self.specs:
            if spec.name in self.registers:
                raise ValueError(f"duplicate register name {spec.name!r}")
            if spec.address in self._address_map:
                raise ValueError(f"duplicate register address {spec.address:#x}")
            register = Register(self, spec)
            self.registers[spec.name] = register
            self._address_map[spec.address] = register

    def __getattr__(self, name):
        registers = self.__dict__.get("registers", {})
        if name in registers:
            return registers[name]
        raise AttributeError(name)

    def register(self, name):
        return self.registers[name]

    def at(self, address):
        return self._address_map[address]

    def bind(self, adapter):
        self.adapter = adapter
        return self

    def reset_mirror(self):
        for register in self.registers.values():
            register.reset_mirror()

    async def check_reset(self):
        """Reset the model mirror, then compare all readable registers."""
        self.reset_mirror()
        for register in self.registers.values():
            if register.spec.readable_mask:
                await register.mirror(check=True)


class RegisterPredictor:
    """Update a register block from monitored AXI4-Lite transactions."""

    def __init__(self, block, analysis_port):
        self.block = block
        self.analysis_port = analysis_port
        analysis_port.subscribe(self.write)

    def write(self, transaction: AxiLiteTransaction):
        register = self.block._address_map.get(transaction.address)
        if register is None or transaction.response != 0:
            return
        if AxiLiteOperation(transaction.operation) is AxiLiteOperation.WRITE:
            register.predict_write(transaction.data, transaction.strobe)
        else:
            register.predict_read(transaction.data)

    def disconnect(self):
        self.analysis_port.unsubscribe(self.write)
