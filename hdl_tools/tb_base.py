"""Protocol-independent building blocks for cocotb agents."""

import inspect
from enum import Enum

import cocotb
from cocotb.queue import Queue


class AgentMode(str, Enum):
    """Whether an agent drives an interface or only observes it."""

    ACTIVE = "active"
    PASSIVE = "passive"


class AnalysisPort[TransactionT]:
    """Multicast transaction output similar to a UVM analysis port.

    Consumers may either await :meth:`get` or register one or more callbacks
    with :meth:`subscribe`. Async callbacks are scheduled as cocotb tasks.
    """

    def __init__(self):
        self._queue = Queue()
        self._subscribers = []

    def subscribe(self, callback):
        self._subscribers.append(callback)
        return callback

    def unsubscribe(self, callback):
        self._subscribers.remove(callback)

    def write(self, transaction: TransactionT):
        self._queue.put_nowait(transaction)
        for callback in tuple(self._subscribers):
            result = callback(transaction)
            if inspect.isawaitable(result):
                cocotb.start_soon(result)

    async def get(self) -> TransactionT:
        return await self._queue.get()

    def get_nowait(self) -> TransactionT:
        return self._queue.get_nowait()

    def empty(self):
        return self._queue.empty()

    def qsize(self):
        return self._queue.qsize()
