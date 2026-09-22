import os
import subprocess
import time

os.makedirs('docs/screenshots', exist_ok=True)

screens = [
    '01_ledger_main',
    '02_transaction_filter_modal',
    '03_ledger_filtered',
    '04_accounts_main',
    '05_personal_debts',
    '06_settle_debt_sheet',
    '07_quick_add_transaction',
    '08_reports_analytics',
]

print("Host screenshot capture daemon started...")
for s in screens:
    ready_cmd = f"adb shell [ -f /sdcard/Download/{s}.ready ] && echo yes || echo no"
    while True:
        try:
            res = subprocess.check_output(ready_cmd, shell=True).decode().strip()
            if res == "yes":
                break
        except Exception:
            pass
        time.sleep(0.3)

    print(f"Capturing screenshot: {s}...")
    time.sleep(0.6)
    out_path = f"docs/screenshots/{s}.png"
    subprocess.run(f"adb exec-out screencap -p > {out_path}", shell=True)
    subprocess.run(f"adb shell touch /sdcard/Download/{s}.done", shell=True)
    size = os.path.getsize(out_path) if os.path.exists(out_path) else 0
    print(f"Saved {out_path} ({size} bytes)")

print("All screenshots captured successfully!")
