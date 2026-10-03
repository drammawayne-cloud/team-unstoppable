#!/usr/bin/env python3
"""Launch the compiled app and take real simulator captures; not UI-interaction tests."""
import json, subprocess, time
from pathlib import Path

def run(*args): return subprocess.check_output(args,text=True).strip()
data=json.loads(run('xcrun','simctl','list','devices','available','--json'))
candidates=[d for runtime, devices in data['devices'].items() if 'iOS' in runtime for d in devices if d.get('isAvailable') and 'iPhone' in d['name']]
if not candidates: raise RuntimeError('No iPhone simulator runtime is installed.')
device=candidates[0]['udid']
subprocess.run(['xcrun','simctl','boot',device],check=False)
subprocess.run(['xcrun','simctl','bootstatus',device,'-b'],check=True)
subprocess.run(['xcrun','simctl','ui',device,'appearance','light'],check=True)
subprocess.run(['xcrun','simctl','status_bar',device,'override','--time','9:41','--batteryState','charged','--batteryLevel','100'],check=False)
subprocess.run(['xcrun','simctl','install',device,'build/Build/Products/Debug-iphonesimulator/TeamUnstoppable.app'],check=True)
subprocess.run(['xcrun','simctl','launch',device,'com.oneteamunstoppable.app'],check=True)
Path('simulator-screenshots').mkdir(exist_ok=True)
time.sleep(5)
for tab in ['home','radio','team','events','more']:
    subprocess.run(['xcrun','simctl','openurl',device,'teamunstoppable://'+tab],check=True)
    time.sleep(2)
    subprocess.run(['xcrun','simctl','io',device,'screenshot',f'simulator-screenshots/{tab}.png'],check=True)
subprocess.run(['xcrun','simctl','terminate',device,'com.oneteamunstoppable.app'],check=True)
print('Simulator launch and five screen captures completed.')
