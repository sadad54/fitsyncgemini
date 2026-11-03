"""A small in-memory stand-in for the supabase-py query builder.

It supports the subset the services use (select with exact counts, eq, in_,
order, range, limit, insert, update, delete, execute), so service logic can be
tested end to end without a network or a real Postgres.
"""
from __future__ import annotations

import copy
import uuid
from dataclasses import dataclass
from typing import Any


@dataclass
class Result:
    data: list[dict[str, Any]]
    count: int | None = None


class _Query:
    def __init__(self, db: "FakeSupabase", table: str):
        self._db, self._table = db, table
        self._filters: list = []
        self._order: list[tuple[str, bool]] = []
        self._range: tuple[int, int] | None = None
        self._limit: int | None = None
        self._op = "select"
        self._payload: Any = None
        self._count = False

    # builders
    def select(self, *_columns, count: str | None = None):
        self._op, self._count = "select", count == "exact"
        return self

    def insert(self, payload):
        self._op, self._payload = "insert", payload
        return self

    def update(self, payload):
        self._op, self._payload = "update", payload
        return self

    def delete(self):
        self._op = "delete"
        return self

    def eq(self, column, value):
        self._filters.append(lambda r: r.get(column) == value)
        return self

    def in_(self, column, values):
        values = list(values)
        self._filters.append(lambda r: r.get(column) in values)
        return self

    def order(self, column, desc: bool = False):
        self._order.append((column, desc))
        return self

    def range(self, start, end):
        self._range = (start, end)
        return self

    def limit(self, n):
        self._limit = n
        return self

    # execution
    def _matching(self) -> list[dict[str, Any]]:
        rows = self._db.tables.setdefault(self._table, [])
        return [r for r in rows if all(f(r) for f in self._filters)]

    def execute(self) -> Result:
        rows = self._db.tables.setdefault(self._table, [])
        if self._op == "insert":
            items = self._payload if isinstance(self._payload, list) else [self._payload]
            added = []
            for item in items:
                row = {"id": str(uuid.uuid4()), **copy.deepcopy(item)}
                for key in self._db.unique.get(self._table, []):
                    if any(all(r.get(k) == row.get(k) for k in key) for r in rows):
                        raise RuntimeError(f"duplicate key on {self._table}{key}")
                rows.append(row)
                added.append(copy.deepcopy(row))
            return Result(added)
        matched = self._matching()
        if self._op == "update":
            for r in matched:
                r.update(copy.deepcopy(self._payload))
            return Result(copy.deepcopy(matched))
        if self._op == "delete":
            self._db.tables[self._table] = [r for r in rows if r not in matched]
            return Result(copy.deepcopy(matched))
        out = matched
        for column, desc in reversed(self._order):
            out = sorted(out, key=lambda r: (r.get(column) is None, r.get(column)), reverse=desc)
        total = len(out)
        if self._range:
            out = out[self._range[0]: self._range[1] + 1]
        if self._limit is not None:
            out = out[: self._limit]
        return Result(copy.deepcopy(out), total if self._count else None)


class FakeSupabase:
    def __init__(self, unique: dict[str, list[tuple[str, ...]]] | None = None):
        self.tables: dict[str, list[dict[str, Any]]] = {}
        self.unique = unique or {}

    def table(self, name: str) -> _Query:
        return _Query(self, name)


class FakeDb:
    """Mimics app.core.database.Database for services that call db.get_client()."""

    def __init__(self, client: FakeSupabase):
        self.client = client

    def get_client(self) -> FakeSupabase:
        return self.client
