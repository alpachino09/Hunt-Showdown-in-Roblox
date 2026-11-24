import gc
import json
import os
import subprocess
import sys
import tempfile
import unittest
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from scripts.studio_mcp import StudioMCPClient, StudioMCPError

FAKE_SERVER = r'''
import json
import sys

initialized = False
for line in sys.stdin:
    request = json.loads(line)
    method = request.get("method")
    request_id = request.get("id")
    if method == "initialize":
        response = {"jsonrpc": "2.0", "id": request_id, "result": {
            "protocolVersion": "2025-06-18", "capabilities": {"tools": {}},
            "serverInfo": {"name": "FakeStudio", "version": "1.0"},
        }}
    elif method == "notifications/initialized":
        initialized = True
        continue
    elif method == "tools/list":
        response = {"jsonrpc": "2.0", "id": request_id, "result": {
            "tools": [{"name": "echo", "description": "Echo arguments"}],
        }}
    elif method == "tools/call" and initialized:
        params = request["params"]
        if params["name"] == "fail":
            result = {"content": [{"type": "text", "text": "denied"}], "isError": True}
        else:
            result = {"content": [{"type": "text", "text": json.dumps(params["arguments"], sort_keys=True)}], "isError": False}
        response = {"jsonrpc": "2.0", "id": request_id, "result": result}
    else:
        response = {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32601, "message": "not ready"}}
    print(json.dumps(response), flush=True)
'''


class StudioMCPClientTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.server = Path(self.temporary.name) / "server.py"
        self.server.write_text(FAKE_SERVER, encoding="utf-8")
        self.command = [sys.executable, str(self.server)]

    def tearDown(self):
        self.temporary.cleanup()

    def test_client_initializes_before_listing_and_calling_tools(self):
        with StudioMCPClient(self.command, timeout=2) as client:
            tools = client.list_tools()
            self.assertEqual([tool["name"] for tool in tools], ["echo"])
            result = client.call_tool("echo", {"value": 42})
            self.assertFalse(result["isError"])
            self.assertEqual(json.loads(result["content"][0]["text"]), {"value": 42})

    def test_tool_error_includes_server_message(self):
        with StudioMCPClient(self.command, timeout=2) as client:
            with self.assertRaisesRegex(StudioMCPError, "denied"):
                client.call_tool("fail", {})

    def test_close_releases_process_streams(self):
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always", ResourceWarning)
            with StudioMCPClient(self.command, timeout=2) as client:
                client.list_tools()
            gc.collect()
            self.assertEqual([item for item in caught if item.category is ResourceWarning], [])

    def test_cli_emits_tool_result_as_json(self):
        env = os.environ.copy()
        env["STUDIO_MCP_COMMAND"] = json.dumps(self.command)
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "studio_mcp.py"), "call", "echo", '{"cli":true}'],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            timeout=5,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(json.loads(payload["content"][0]["text"]), {"cli": True})


if __name__ == "__main__":
    unittest.main()
