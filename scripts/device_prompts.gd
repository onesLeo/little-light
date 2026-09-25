extends RefCounted
## Prompts are written for the keyboard ("Press Space to continue", "Press E to collect").
## On a tablet or a gamepad they name that device's buttons instead. Every story words its
## prompts through here, so the three devices read the same way everywhere.
##
## On a tablet there is one gold action button, and its label follows the story
## (touch_controls.gd): each story says what to call it in its prompts.
##   button   what "Press E" / "Hold E" taps: the valley's says GRAB; the ark's label changes
##            from step to step, so it is "the gold button"
##   hold     what "Hold Space" holds: BREATHE in Steady Hands, LOOP for the camp's cord
## Use through a preload constant (no class_name):
##   const DevicePrompts := preload("res://scripts/device_prompts.gd")
##   DevicePrompts.reword("Press E to collect", input_setup, "GRAB")

const GOLD_BUTTON := "the gold button"

## Longest first, so "Hold Space / Enter or the button" is not caught by "Hold Space".
const KEYS := [
	"Hold Space / Enter or the button", "Hold Space", "Press Space",
	"Press E", "press E", "Hold E",
	"[A / D: look around]", "A / D or arrows: look around",
]


## `raw` worded for the device `input_setup` (input_setup.gd) says was used last; the keyboard's
## wording as it is. With no InputSetup (a trimmed scene), the keyboard's.
static func reword(raw: String, input_setup: Node, button: String = GOLD_BUTTON, hold: String = "the button") -> String:
	var mode: String = input_setup.mode if input_setup and "mode" in input_setup else "keyboard"
	return for_mode(raw, mode, button, hold)


static func for_mode(raw: String, mode: String, button: String = GOLD_BUTTON, hold: String = "the button") -> String:
	var words := {}
	match mode:
		"touch":
			words = {
				"Hold Space / Enter or the button": "Hold " + hold, "Hold Space": "Hold " + hold,
				"Press Space": "Tap NEXT", "Press E": "Tap " + button, "press E": "tap " + button,
				"Hold E": "Hold " + button,
				"[A / D: look around]": "[stick: look around]", "A / D or arrows: look around": "stick: look around",
			}
		"gamepad":
			words = {
				"Hold Space / Enter or the button": "Hold A", "Hold Space": "Hold A",
				"Press Space": "Press A", "Press E": "Press A", "press E": "press A", "Hold E": "Hold A",
				"[A / D: look around]": "[stick: look around]", "A / D or arrows: look around": "stick: look around",
			}
		_:
			return raw
	var text := raw
	for key in KEYS:
		text = text.replace(key, words[key])
	return text
