#!/usr/bin/env python3
"""Run real navigation/bookmark UI tests and export XCTest screenshot attachments."""
import json, subprocess, os
from pathlib import Path

def run(*args): return subprocess.check_output(args,text=True).strip()
data=json.loads(run('xcrun','simctl','list','devices','available','--json'))
candidates=[d for runtime, devices in data['devices'].items() if 'iOS' in runtime for d in devices if d.get('isAvailable') and 'iPhone' in d['name']]
if not candidates: raise RuntimeError('No iPhone simulator runtime is installed.')
device=candidates[-1]['udid']
subprocess.run(['xcrun','simctl','boot',device],check=False,timeout=90)
subprocess.run(['xcrun','simctl','bootstatus',device,'-b'],check=True,timeout=360)
subprocess.run(['xcrun','simctl','ui',device,'appearance','light'],check=True,timeout=30)
subprocess.run(['xcrun','simctl','status_bar',device,'override','--time','9:41','--batteryState','charged','--batteryLevel','100'],check=False,timeout=30)
command=['xcodebuild','test','-project','mobile/ios/TeamUnstoppable.xcodeproj','-scheme','TeamUnstoppable','-configuration','Debug','-sdk','iphonesimulator','-destination',f'platform=iOS Simulator,id={device}','-derivedDataPath','build','-resultBundlePath','ui-results.xcresult','-parallel-testing-enabled','NO','-only-testing:TeamUnstoppableUITests/SmokeTests','CODE_SIGNING_ALLOWED=NO']
result=subprocess.run(command,timeout=420)
if Path('ui-results.xcresult').exists():
    subprocess.run(['xcrun','xcresulttool','export','attachments','--path','ui-results.xcresult','--output-path','simulator-screenshots'],check=True,timeout=60)
if result.returncode: raise SystemExit(result.returncode)
print('Native tab navigation and saved-profile UI test passed; screenshots exported.')
