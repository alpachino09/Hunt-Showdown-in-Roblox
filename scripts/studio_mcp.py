import argparse
import json
import os
import select
import shlex
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_COMMAND = ["/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"]


class StudioMCPError(RuntimeError):
    pass


class StudioMCPClient:
    def __init__(self, command=None, timeout=15):
        self.command = list(command or DEFAULT_COMMAND)
        self.timeout = timeout
        self.process = None
        self.next_id = 0

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def start(self):
        if self.process is not None:
            return
        self.process = subprocess.Popen(
            self.command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self.request(
            "initialize",
            {
                "protocolVersion": "2025-06-18",
                "capabilities": {},
                "clientInfo": {"name": "grey-outpost-tools", "version": "1.0"},
            },
        )
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})

    def send(self, payload):
        self.start() if self.process is None else None
        assert self.process is not None and self.process.stdin is not None
        self.process.stdin.write(json.dumps(payload, separators=(",", ":")) + "\n")
        self.process.stdin.flush()

    def request(self, method, params):
        self.start() if self.process is None else None
        self.next_id += 1
        request_id = self.next_id
        self.send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            assert self.process is not None and self.process.stdout is not None
            remaining = deadline - time.monotonic()
            readable, _, _ = select.select([self.process.stdout], [], [], remaining)
            if not readable:
                break
            line = self.process.stdout.readline()
            if not line:
                error = self.process.stderr.read() if self.process.stderr is not None else ""
                raise StudioMCPError(f"Studio MCP closed stdout: {error.strip()}")
            try:
                response = json.loads(line)
            except json.JSONDecodeError:
                continue
            if response.get("id") != request_id:
                continue
            if "error" in response:
                raise StudioMCPError(response["error"].get("message", str(response["error"])))
            return response.get("result", {})
        raise StudioMCPError(f"Studio MCP request timed out: {method}")

    def list_tools(self):
        return self.request("tools/list", {}).get("tools", [])

    def call_tool(self, name, arguments):
        result = self.request("tools/call", {"name": name, "arguments": arguments})
        if result.get("isError"):
            text = "\n".join(item.get("text", "") for item in result.get("content", []))
            raise StudioMCPError(text or f"Studio tool failed: {name}")
        return result

    def close(self):
        if self.process is None:
            return
        process = self.process
        self.process = None
        if process.stdin is not None:
            process.stdin.close()
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)
        if process.stdout is not None:
            process.stdout.close()
        if process.stderr is not None:
            process.stderr.close()


def configured_command():
    value = os.environ.get("STUDIO_MCP_COMMAND")
    if not value:
        return DEFAULT_COMMAND
    try:
        command = json.loads(value)
    except json.JSONDecodeError:
        command = shlex.split(value)
    if not isinstance(command, list) or not all(isinstance(part, str) for part in command):
        raise StudioMCPError("STUDIO_MCP_COMMAND must be a command or JSON string array")
    return command


def main(argv=None):
    parser = argparse.ArgumentParser(description="Call the local Roblox Studio MCP server")
    parser.add_argument("command", choices=("list-tools", "call"))
    parser.add_argument("tool", nargs="?")
    parser.add_argument("arguments", nargs="?", default="{}")
    args = parser.parse_args(argv)
    if args.command == "call" and not args.tool:
        parser.error("call requires a tool name")
    arguments = json.loads(args.arguments)
    if not isinstance(arguments, dict):
        parser.error("tool arguments must be a JSON object")
    with StudioMCPClient(configured_command()) as client:
        result = client.list_tools() if args.command == "list-tools" else client.call_tool(args.tool, arguments)
        print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))


if __name__ == "__main__":
    try:
        main()
    except (StudioMCPError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
