"""Noah's wife. See generate_noah_v1.py for the shared paper-people build."""
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("noah_builder", HERE / "generate_noah_v1.py")
noah = importlib.util.module_from_spec(spec)
spec.loader.exec_module(noah)

if __name__ == "__main__":
    noah.build_person("wife")
