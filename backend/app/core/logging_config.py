import logging
import os

def setup_logging():
    log_level_str = os.getenv("LOG_LEVEL", "DEBUG").upper()
    log_level = getattr(logging, log_level_str, logging.DEBUG)
    
    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
class PrefixFilter(logging.Filter):
    def __init__(self, prefix="APP"):
        super().__init__()
        self.prefix = prefix
        
    def filter(self, record):
        if not hasattr(record, 'prefix'):
            record.prefix = self.prefix
        return True

def get_logger(name: str, prefix: str = "APP") -> logging.Logger:
    logger = logging.getLogger(name)
    # Avoid adding multiple filters if logger is requested multiple times
    if not any(isinstance(f, PrefixFilter) for f in logger.filters):
        logger.addFilter(PrefixFilter(prefix=prefix))
    return logger
