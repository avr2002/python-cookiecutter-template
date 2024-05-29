import sys
from pathlib import Path


THIS_DIR = Path(__file__).parent
sys.path.insert(0, str(THIS_DIR.parent))