from pathlib import Path
import json, re, subprocess
base=Path(__file__).resolve().parents[1]
a=base/'sound/400 Sounds Pack'; b=base/"sound/Helton Yan's Pixel Combat"
picks={
 'ui_hover':a/'UI/sci_fi_hover.wav', 'ui_click':a/'UI/select_1.wav',
 'pause_open':a/'UI/toggle_on.wav','pause_close':a/'UI/toggle_off.wav',
 'ui_error':a/'UI/sci_fi_disallow.wav','drag_pickup':a/'UI/pop_1.wav',
 'frame_shift':a/'UI/sci_fi_confirm.wav','panel_switch':b/'UIMisc_INTERFACE-Zap Select_HY_PC.wav',
 'double_jump':b/'DSGNMisc_MOVEMENT-Jump Sparkle_HY_PC.wav',
 'dash':b/'SWSH_MOVEMENT-Sparkle Passby_HY_PC.wav',
 'footstep_1':a/'Footsteps/foley_footstep_concrete_1.wav',
 'footstep_2':a/'Footsteps/foley_footstep_concrete_2.wav',
 'landing':a/'Footsteps/foley_footstep_concrete_4.wav',
 'swing_1':a/'Weapons/sword_light.wav','swing_2':a/'Weapons/sword_slice.wav',
 'heavy_swing':b/'DSGNMisc_MELEE-Bit Sword_HY_PC.wav',
 'hit':b/'FGHTImpt_HIT-Smack_HY_PC.wav','heavy_hit':b/'FGHTImpt_HIT-Strong Smack_HY_PC.wav',
 'slam':b/'DSGNImpt_EXPLOSION-Sand Impact_HY_PC.wav',
 'parry_start':a/'Weapons/weapon_equip_short.wav','parry_success':b/'DSGNMisc_MELEE-Sword Parry_HY_PC.wav',
 'enemy_windup':a/'UI/synth_warning.wav','enemy_swing':a/'Combat and Gore/swipe.wav',
 'enemy_shot':b/'DSGNMisc_HIT-Mecha Laser Pistol_HY_PC.wav',
 'hurt':b/'DSGNMisc_HIT-Synth Hit_HY_PC.wav',
 'enemy_death':b/'DSGNSynth_BUFF-Enemy Debuff_HY_PC.wav',
 'add_collect':a/'Items/coins_gather_quick.wav',
 'add_ready':a/'UI/synth_confirmation.wav',
 'mult_collect':b/'DSGNTonl_USABLE-Magic Coin_HY_PC.wav',
 'mult_ready':b/'DSGNSynth_BUFF-Mecha Level Up_HY_PC.wav',
 'dilate_start':b/'MAGSpel_CAST-Energy Riser_HY_PC.wav',
 'dilate_end':a/'UI/synth_cancel.wav',
 'wave_start':a/'UI/sci_fi_select_big.wav',
 'wave_clear':a/'UI/synth_process_complete.wav',
 'defeat':a/'Musical Effects/synth_bass_negative_quick.wav',
 'victory':a/'Musical Effects/brass_chime_quick.wav',
 'restart':a/'UI/synth_shut_down.wav',
}
missing=[str(p) for p in picks.values() if not p.exists()]
if missing: raise SystemExit(missing)
manifest={}
for name, source in picks.items():
 r=subprocess.run(['ffmpeg','-hide_banner','-i',str(source),'-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True)
 match=re.search(r'max_volume: ([\-\d.]+) dB',r.stderr)
 gain=min(12.0,-3.0-float(match.group(1))) if match else 0.0
 dest=base/'assets/audio'/f'{name}.ogg'
 subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(source),'-vn','-map','0:a:0','-af',f'atrim=end={4 if source.parent == b else 8},silenceremove=start_periods=1:start_threshold=-50dB:start_duration=0.003,areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_duration=0.003,areverse,volume={gain}dB','-ac','1','-ar','44100','-c:a','libvorbis','-q:a','4',str(dest)],check=True)
 manifest[name]={'source':str(source.relative_to(base)),'runtime':str(dest.relative_to(base)),'peak_gain_db':round(gain,2),'selection':'First variation only; silent padding removed' if source.parent == b else 'Silent padding removed'}
(base/'assets/audio/SOURCES.json').write_text(json.dumps(manifest,indent=2)+'\n')
(base/'sound/.gdignore').touch()
print(len(manifest),'prepared clips,',sum((base/x['runtime']).stat().st_size for x in manifest.values()),'bytes')
