#!/usr/bin/env python3
"""Exercise the distributed executable's stdio protocol, optionally with a UI-authorized folder."""
import argparse
import json
import pathlib
import resource
import sys
import select
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--executable', required=True)
access = parser.add_mutually_exclusive_group()
access.add_argument('--root', help='Synthetic test folder already allowed through Zforge Settings')
access.add_argument('--revoked-root', help='Revoked synthetic folder; cancel its contextual picker to verify denial')
args = parser.parse_args()
started = time.monotonic()
process = subprocess.Popen([args.executable, '--mcp'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, text=True, bufsize=1)
sequence = 0
checks = []

def send(method, params=None, notification=False):
    global sequence
    message = {'jsonrpc': '2.0', 'method': method}
    if params is not None:
        message['params'] = params
    if not notification:
        sequence += 1
        message['id'] = sequence
    process.stdin.write(json.dumps(message) + '\n')
    process.stdin.flush()
    if notification:
        return
    deadline = time.monotonic() + (120 if args.revoked_root else 20)
    while time.monotonic() < deadline:
        ready, _, _ = select.select([process.stdout], [], [], max(0, deadline - time.monotonic()))
        assert ready, 'Timed out waiting for protocol response'
        line = process.stdout.readline()
        assert line, 'Server exited before returning a response'
        response = json.loads(line)
        if response.get('id') == sequence:
            assert 'error' not in response, response
            return response['result']
    raise AssertionError('Missing response')

def tool(name, **arguments):
    return send('tools/call', {'name': name, 'arguments': arguments})

def job(result):
    assert result.get('isError') is False, result
    identifier = result['structuredContent']['operation_id']
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        state = tool('operation_status', operation_id=identifier)['structuredContent']
        if state['state'] in ('succeeded', 'failed', 'cancelled'):
            assert state['state'] == 'succeeded', state
            return state
    raise AssertionError('Job did not complete within fixture deadline')

try:
    initialized = send('initialize', {'protocolVersion': '2025-11-25', 'capabilities': {},
                                    'clientInfo': {'name': 'ZforgeStdioSmoke', 'version': '1.0'}})
    assert initialized['serverInfo']['name'] == 'Zforge'
    initialize_seconds = time.monotonic() - started
    send('notifications/initialized', notification=True)
    definitions = send('tools/list')
    assert len(definitions['tools']) == 8
    checks.append('initialize/discovery')
    capabilities = tool('get_capabilities')
    assert capabilities['structuredContent']['transport'] == 'stdio'
    checks.append('capabilities')
    if args.revoked_root:
        revoked = tool('list_directory', path=args.revoked_root)
        assert revoked['isError'] is True and revoked['structuredContent']['error_code'] == 'cancelled'
        checks.append('removed UI grant requests new consent; cancellation denies access')
    denied = tool('list_directory', path='/ZforgeUnapprovedSmokeFolder')
    assert denied['isError'] is True and denied['structuredContent']['error_code'] == 'authorizationRequired'
    checks.append('unapproved access denied')
    invalid = tool('list_directory', path='/ZforgeUnapprovedSmokeFolder', show_hidden=1)
    assert invalid['isError'] is True and invalid['structuredContent']['error_code'] == 'invalidArguments'
    checks.append('typed arguments')
    if args.root:
        root = pathlib.Path(args.root)
        source = root / 'Stdio Input.txt'
        source.write_text('Zforge stdio fixture\n')
        listing = tool('list_directory', path=str(root))
        assert listing.get('isError') is False, listing
        assert any(item['name'] == source.name for item in listing['structuredContent']['items'])
        for format_name in ('zip', '7z'):
            archive = root / ('Stdio Output.' + format_name)
            job(tool('compress', sources=[str(source)], destination=str(archive), format=format_name))
            page = tool('list_archive', path=str(archive))
            assert page.get('isError') is False, page
            assert [item['name'] for item in page['structuredContent']['items']] == [source.name]
            job(tool('test_archive', archive=str(archive)))
            output = root / ('Stdio Extracted ' + format_name)
            job(tool('extract', archive=str(archive), destination=str(output)))
            assert (output / source.name).read_bytes() == source.read_bytes()
            replacement = tool('compress', sources=[str(source)], destination=str(archive), format=format_name)
            assert replacement['isError'] is True and replacement['structuredContent']['error_code'] == 'destinationExists'
        checks.append('UI grant -> real ZIP/7z round-trips and no replacement')
    process.stdin.close()
    process.wait(timeout=10)
    assert process.returncode == 0, process.returncode
    stderr = process.stderr.read()
    assert not stderr.strip(), 'Unexpected stderr output'
    usage = resource.getrusage(resource.RUSAGE_CHILDREN)
    maxrss = usage.ru_maxrss if sys.platform == 'darwin' else usage.ru_maxrss * 1024
    print(json.dumps({'checks': checks, 'initialize_seconds': initialize_seconds,
                      'child_user_cpu_seconds': usage.ru_utime, 'child_system_cpu_seconds': usage.ru_stime,
                      'child_maxrss_bytes': maxrss,
                      'elapsed_seconds': time.monotonic() - started, 'exit_code': process.returncode}, indent=2))
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
