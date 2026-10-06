"""Run all applicable gameplay suites; fail on engine errors as well as assertions."""
from pathlib import Path
import json, subprocess, time
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build' / 'qa'
OUT.mkdir(parents=True, exist_ok=True)
SUITES = ['player_movement','player_melee','player_stage3','player_stage4','keyboard_input','ember_sprite','causal_lifecycle','causal_swap_score','causal_damage','causal_pause_ui','time_dilation','dilation_clock','singularity','ranged_enemy','shared_health_warning','enemy_switch_movement','causal_end_to_end','causal_bounds','wave_difficulty','wave_combat','manga_ui','damage_numbers','frame_shift_followup','sound_design']
# Keep simulation deterministic but give Jolt workers time between accelerated frames.
results = []
for suite in SUITES:
    start = time.monotonic()
    try:
        run = subprocess.run(['godot','--headless','--fixed-fps','60','--frame-delay','5','--path',str(ROOT),'--script',f'tests/{suite}_test.gd'],capture_output=True,text=True,timeout=60)
        output = run.stdout + run.stderr
        good = run.returncode == 0 and 'COMPLETE' in output and not any(s in output for s in ['SCRIPT ERROR','ERROR:','FAIL:'])
        warnings = [line for line in output.splitlines() if 'WARNING:' in line]
    except subprocess.TimeoutExpired as e:
        output, good, warnings = str(e), False, []
    (OUT / f'{suite}.log').write_text(output)
    results.append({'suite':suite,'passed':good,'seconds':round(time.monotonic()-start,2),'checks':output.count('PASS:'),'warnings':warnings})
    print(f'{"PASS" if good else "FAIL"}: {suite}', flush=True)
(OUT / 'results.json').write_text(json.dumps(results,indent=2))
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
