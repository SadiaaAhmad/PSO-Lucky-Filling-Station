import time
from typing import Dict, Any, Optional

class SimpleTTLCache:
    def __init__(self, default_ttl_seconds: int = 120):
        self._cache: Dict[str, Any] = {}
        self._timestamps: Dict[str, float] = {}
        self.default_ttl = default_ttl_seconds

    def get(self, key: str) -> Optional[Any]:
        if key not in self._cache:
            return None
        elapsed = time.time() - self._timestamps.get(key, 0)
        if elapsed > self.default_ttl:
            self.invalidate(key)
            return None
        return self._cache[key]

    def set(self, key: str, value: Any, ttl_seconds: Optional[int] = None):
        self._cache[key] = value
        self._timestamps[key] = time.time()

    def invalidate(self, key: str):
        self._cache.pop(key, None)
        self._timestamps.pop(key, None)

    def clear(self):
        self._cache.clear()
        self._timestamps.clear()

# Global API Cache Instance
api_cache = SimpleTTLCache(default_ttl_seconds=120)
