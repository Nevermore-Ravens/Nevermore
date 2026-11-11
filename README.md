# <div align="center">Nevermore</div>
<div align="center">
Nevermore is a vertical scrolling rhythm game (VSRG) engine made in HaxeFlixel.  

It's primarily designed for keyboard/gamepad play, something along the lines of [Etterna](https://github.com/etternagame/etterna), [StepMania](https://github.com/stepmania/stepmania), [osu!mania](https://osu.ppy.sh), or [Quaver](https://github.com/Quaver/Quaver).

It supports "multi-key" (as in 5k, 6k, 7k, etc...), but it's mainly intended to be used with 4 keys/lanes.

</div/>

# Features

## Easy to set up gameplay
Setting up gameplay is very straightforward.
```hx
import nevermore.skins.Noteskin;
import nevermore.play.*;
import nevermore.core.Conductor;
import nevermore.core.Song;

Nevermore.init();

var skin = Noteskin.get('funkin');
var songID:String = 'Cyber Inductance';
var difficulty:String = 'Hard';

// make a strumline
var strumline = new Strumline(0, 50, skin);
strumline.screenCenter(X);

// make a notefield
var notefield = new NoteField([strumline], 0);
add(notefield);

// load the audio and chart
Conductor.inst = FlxG.sound.load(Assets.audio(songID + '/Inst'));

// Song.load() will work if you have `moonchart` labeled as a library,
// otherwise it won't do anything and you'll have to implement your own parser
notefield.load(Song.load('songs/' + songID + '/chart.sm', difficulty), {
	randomizedNotes: true,
	sustains: false
});

// start
Conductor.play();
```

## Modcharting
Nevermore supports modcharting, the likes of something you'd see on NotITG.  
Albeit, it might be a little lackluster in terms of how much it's capable of.

(see [ModchartManager.hx](src/nevermore/modchart/ModchartManager.hx) for more)
```hx
import nevermore.modchart.ModchartManager;

var notefield = new NoteField();
add(notefield);

var modchart = new ModchartManager();
modchart.setAt(2, 'drunk', 0.75);
modchart.setAt(3, 'tipsy', 2);
// also supports ProxyFields if that's your kinda thing

notefield.modchart = modchart;
```

## Scroll Velocities
Nevermore supports scroll velocities as well, referenced and tested with Quaver maps/charts.  
All you have to do is give your chart a list of scroll velocities to use via `nevermore.core.Chart.scrollVelocities`.  
(see [ScrollVelocity.hx](./src/nevermore/core/timing/ScrollVelocity.hx) for more)

## Quantization
Nevermore supports note quantization, which is the colour of notes depending on the snap they're at between 2 beats.  
It can be turned on with `Nevermore.settings.quantization`.  
(see [NoteColor.hx](./src/nevermore/core/NoteColor.hx) for more)

# FAQ
## "Why was this made, and not built directly into Never2x?"
A couple of reasons.
* Parity (Camellia -> Never2x, Never2x -> Camellia)
	- Writing code for Camellia at the same time of developing Never2x got EXTREMELY annoying.   
	Camellia would have a bug with gameplay that got fixed, and then you would have to  
	copy paste that SAME FIX over to the Never2x repo, since both repos are basically the fork/"engine"  
	copy pasted twice.  
	Not only that, there'd be a chance the fix wouldn't work, because of project specific changes,  
	so you would have to recreate the fix AGAIN.
	
* I've always wanted to do a thing like this
	- I've always wanted to make some sort of rhythm game library that people can learn from, so having  
	a chance to do this was, kinda perfect.

* The codebase was getting VERY messy
	- There were alot of things with the codebase I wasn't really a fan of. Whether it was the code itself,  
	the architecture/API, or just how things were organized.

## "What is Never2x, exactly?"
A fork of Friday Night Funkin' that is primarily aimed towards gameplay.                              
When we were still developing Camellia 2.75, alot of the engines (Psych, Codename, Base Game)  
didn't run very well, or were either too shit to work with, and required too much modification to work well enough.  
So, we decided "fuck it", and made our own instead.  

The name is still a secret, and does in fact mean something.  
All in due time.

## "What happened to Never2x? Is it discontinued!?"
No, not at all! I made this SPECIFICALLY so I could work on Never2x easier, and more consistently across projects.  
Nevermore is the core gameplay of the project;  
Never2x is the FNF front-end of Nevermore;  
Camellia is that, but slightly modified for the mod.
Both normal Never2x and Camellia use Nevermore as a library, which means both keep the same core gameplay loop.  
This also means I don't have to keep copy-pasting changes between the 2 over and over.

# Credits
* RapperGF - Assisting in developing architecture and API
* Marsh - Bugfixes and scroll velocity support
* SrtPro278 - Modchart, sustain, and quantization functionality/rendering
* Vs. Camellia - Allowing me to make Never2x

# <div align="center">Artificial Intelligence (such as ChatGPT, Claude, Gemini, Github Copilot, DeepSeek) has not been used and/or assisted in the making of this project.</div>
