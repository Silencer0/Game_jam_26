"""Prepare the owner's three soundtrack versions on one equal-length loop."""
from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[1]
tracks={'Past':'Iron Velocity.wav','Present':'heavy rock cover.wav','Future':'80s Synthwave Remix.wav'}
lengths={}
for role,name in tracks.items():
 result=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1',str(root/'sound/bgm'/name)],capture_output=True,text=True,check=True)
 lengths[role]=float(result.stdout)
loop=min(lengths.values())
manifest={'loop_seconds':loop,'tracks':{}}
for role,name in tracks.items():
 source=root/'sound/bgm'/name; dest=root/'assets/audio/music'/(role.lower()+'.ogg')
 subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(source),'-vn','-map','0:a:0','-t',str(loop),'-af',f'loudnorm=I=-18:TP=-3:LRA=9,afade=t=out:st={loop-0.08}:d=0.08','-ac','2','-ar','44100','-c:a','libvorbis','-q:a','4',str(dest)],check=True)
 manifest['tracks'][role]={'source':str(source.relative_to(root)),'runtime':str(dest.relative_to(root)),'original_seconds':lengths[role]}
(root/'assets/audio/music/SOURCES.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Prepared three synchronized',loop,'second loops')
