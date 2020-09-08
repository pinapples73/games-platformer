# games-platformer
Platform game code made using Godot.

Download Godot here:- https://godotengine.org/

This project is in very early stages in an attempt to learn how to code games using the Godot Engine. I don't have a game design as such but I am just attempting to code common platformer mechanics.

The player has the following states. These will be expanded when the games design matures.
1) DEFAULT = normal on ground state with ability to move left and right and jump.
2) AIRBOURNE = triggered when you eitehr jump or fall from a platform. Detecting ledges and walls and double jumps are also processed here.
3) HANGING = triggered when the player had detected a ledge near enough to grab onto.  This is triggered when the player is airbourne and is falling. So ledges wont be detected on the way up from a jump for instance.
4) DASHING = a quick dash left or right with a cooldown timer
5) WALLJUMPING = when making contact with a wall while airbourne the player can then jump off that wall
6) CLIMBING = when making contact with a particular type of wall the player can press a button and cling to that wall and climb up and down.

Currently working on State 6) CLIMBING

Below are some further mechanics I will attempt to code.

1) Using Ladders
2) Combat (melee and projectile)
3) Rope climbing


