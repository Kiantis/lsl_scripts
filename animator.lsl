
/*
Animator
General purpose AO + on request animations
for specific objects (ex. wings, tail)
For requestable animations click the object, no HUD required.
More specs at end of script.
@Author kiantis.oe
*/

/*
  E X T E R N A L   M E T H O D S 
  External methods access NO global variable by design.
  It is safer to control the flow of global method in the 'FLOW' part (the actual SL default{...} thingy)
*/


/**
 * Goes through the inventory, re-reads all the animation files,
 * and updates the reference map.
 */
list parseInventory() {
  list result;
  integer count = llGetInventoryNumber(INVENTORY_ANIMATION);
  while (count--) {
    result += llGetInventoryName(INVENTORY_ANIMATION, count);
  }
  return result;
}


/**
 * Parse the animation list and extract only the AO ones.
 */
list extractAO(list animations) {
  string name;
  list result;
  integer exclude;
  integer count = llGetListLength(animations);
  while (count--) {
    name = llList2String(animations, count);
    name = trim(name);
    // Standing anims can have multiple stages, ignore if they have a suffix
    if (llSubStringIndex(name, "AO Standing") != -1 &&
        llStringLength(name) > llStringLength("AO Standing")) {
      exclude = TRUE;
    } else {
      exclude = FALSE;
    }
    // Take only the ones with prefix
    if (!exclude && llGetSubString(name, 0, 2) == "AO ") {
      result += name;
    }
  }
  return result;
}


/**
 * Does the opposite of extractAO
 */
list exctractRequestable(list animations) {
  string name;
  list result;
  integer count = llGetListLength(animations);
  while (count--) {
    name = llList2String(animations, count);
    name = trim(name);
    // Take only the ones with NO prefix
    if (llGetSubString(name, 0, 2) != "AO " && name != "init") {
      result += name;
    }
  }
  return result;
}


/**
 * Get the ao codename from a string with the _AO_ prefix
 */
string unprefixAO(string s) {
  return llGetSubString(s, 3, llStringLength(s));
}


/**
 * Trim a string
 */
string trim(string s) {
  return llDumpList2String(llParseString2List(s, [" "], []), " ");
}


/**
 * Reorders the dialog buttons so that they appear from top-left and they go to right-bottom
 */
list reorderDialogButtons(list buttons) {
  return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
       + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

/**
 * Return true if the animation is existing in the inventory.
 */
integer isValidAnimation(string animation) {
  if (animation == "") {
    return FALSE;
  }
  return llGetInventoryType(animation) != INVENTORY_NONE;
}


/**
 * Apply all the animation overrides present in the list.
 */
applyALLAO(list animationsAO) {
  string nameAnimation;
  string nameAO;
  string currentAppliedAnimation;
  integer count = llGetListLength(animationsAO);
  while (count--) {
    nameAnimation = llList2String(animationsAO, count);
    nameAO = trim(unprefixAO(nameAnimation));
    currentAppliedAnimation = llGetAnimationOverride(nameAO);
    // Apply-Reapply only if it the same animation that is in the inventory
    if (currentAppliedAnimation != nameAnimation) {
      llSetAnimationOverride(nameAO, nameAnimation);
    }
  }

  string cyclingAnimName = "AO Standing" + ((string)gStandingCount);
  if (llGetInventoryType(cyclingAnimName) != INVENTORY_NONE) {
    llSetAnimationOverride("Standing", cyclingAnimName);
  }
}


/**
 * An animation was requested through dialog.
 */
requestAnimation(string animation) {
  
  if (!isValidAnimation(animation)) {
    return;
  }

  llStartAnimation(animation);

}


/**
 * A STOP was issued through dialog.
 */
stopRequestedAnimation() {

  integer count = llGetListLength(gAnimationsRequestable);
  while (count--) {
    string animation = llList2String(gAnimationsRequestable, count);
    if (isValidAnimation(animation)) {
      llStopAnimation(animation);
    }
  }

  // If there is an init, then go the init way over again.
  if (llGetInventoryType("init") != INVENTORY_NONE) {
    llStartAnimation("init");
  }
  // AO need no reset, they will take over in such case.

}


/**
 * The initial decision point once the permission are given.
 * From here the animations can start.
 */
animatorCanInitialize(list animationsAO) {

  integer hasInitAnimation = llGetInventoryType("init") != INVENTORY_NONE;

  // There are two possible flows here.
  // If the user has specified an animation called 'init'
  // then the AOs will NOT be done AT ALL and the init will
  // be the starting point always at any time also the requestable
  // animations will be stopped.
  // This is sometimes useful in case of pieces such a tail that always animates
  // no matter the pose. Plus having multiple AOs from multiple objects can also
  // interfere, so it is plausible to want a init only.
  if (hasInitAnimation) {
    llStartAnimation("init");
  } else {
    // Apply all the AOs
    applyALLAO(animationsAO);
  }
}


/**
 * Checks and resets all periodically (called by the ti)
 */
preventReset(string lastRequestedAnimation, list animationsAO) {
  string animationToCheck = lastRequestedAnimation;
  // if not a valid anim, then try the init one
  if (!isValidAnimation(animationToCheck)) {
    animationToCheck = "init";
  }
  // Anim was not the requested one? Apply it again.
  if (isValidAnimation(animationToCheck)) {
    string activeAnimations = llDumpList2String(llGetAnimationList(llGetOwner()), " - ");
    key requestedAnimKey = llGetInventoryKey(animationToCheck);
    // If not found in active animations, retrigger it
    if (llSubStringIndex(activeAnimations, (string) requestedAnimKey) == -1) {
      llStartAnimation(animationToCheck);
    }
  }

  integer hasInitAnimation = llGetInventoryType("init") != INVENTORY_NONE;
  if (!hasInitAnimation) {
    applyALLAO(animationsAO);
  }

}


/*
  G L O B A L S
*/

list gAnimations;
list gAnimationsAO;
list gAnimationsRequestable;
list gListMenu;
integer gListenDialogChannel;
integer gListenDialogHandle;
integer gStandingCount;
string gPreviousAnimation;
// How frequent the main timer tick will be, all other counters will be based on this number
// Number is a float in unit of seconds
float gTimerTickPeriod = 1.0;
// The current timer tick, it increments at each tick.
integer gTimerTickCount;
// How much time the AOs will cycle (in ticks)
integer gTimerForAOCycle = 30;
// How much time to check that anims are still running and reapply if they are not
integer gTimerForPreventReset = 2;


/*
  F L O W
*/

default {

  attach(key id) {

    // Unlisten first
    if (gListenDialogHandle) {
      llListenRemove(gListenDialogHandle);
    }

    gStandingCount = 1;
    gTimerTickCount = 1;

    // Create random channel
    gListenDialogChannel = (integer)(llFrand(10000.0) + 10000.0);
    gListenDialogHandle = llListen(gListenDialogChannel, "", "","");
    //llOwnerSay("animator channel for " + llGetObjectName() + " : " + ((string) gListenDialogChannel));

    gAnimations = parseInventory();
    gAnimationsAO = extractAO(gAnimations);
    gAnimationsRequestable = exctractRequestable(gAnimations);
    gListMenu = gAnimationsRequestable;

    // Start by requesting permissions, all else will follow
    // Need to request them both because one will cancel the other
    // if requested singularly.
    llRequestPermissions(id, 
      PERMISSION_OVERRIDE_ANIMATIONS |
      PERMISSION_TRIGGER_ANIMATION);

  }

  run_time_permissions(integer perms) {

    integer hasAOPerm = perms & PERMISSION_OVERRIDE_ANIMATIONS;
    integer hasAnimPerm = perms & PERMISSION_TRIGGER_ANIMATION;
    integer hasBoth = hasAOPerm && hasAnimPerm;
    integer hasOnlyOne = (hasAOPerm || hasAnimPerm) && !hasBoth;

    if (hasOnlyOne) {
      llOwnerSay("Requested both " +
        "PERMISSION_OVERRIDE_ANIMATIONS + " +
        " PERMISSION_TRIGGER_ANIMATION, " + 
        "but only one was given.");
      return;
    }

    if (hasBoth) {
      stopRequestedAnimation();
      animatorCanInitialize(gAnimationsAO);
      llSetTimerEvent(gTimerTickCount);
    }

  }

  touch_start(integer num_detected) {
    list dialogItems = reorderDialogButtons(gListMenu);
    dialogItems += "STOP";
    llDialog(llDetectedKey(0), "\n", dialogItems, gListenDialogChannel);
  }

  listen(integer channel, string name, key id, string message) {

    if (channel != gListenDialogChannel) {
      return;
    }

    stopRequestedAnimation();
    if (message == "STOP") { 
      gPreviousAnimation = "";
    } else {
      gPreviousAnimation = message;
      requestAnimation(message);
    }

  }

  timer() {

    if (gTimerTickCount % gTimerForPreventReset == 0) {
      preventReset(gPreviousAnimation, gAnimationsAO);
    }

    if (gTimerTickCount % gTimerForAOCycle == 0) {
      // In case there was an AO set present, the standing animations
      // will keep cycling until there are available in the inventory.
      // (only the sitting AOs)
      string animName = "AO Standing" + ((string)gStandingCount);
      if (llGetInventoryType(animName) != INVENTORY_NONE) {
        llSetAnimationOverride("Standing", animName);
        gStandingCount = gStandingCount + 1;
      } else {
        gStandingCount = 1;
      }
    }

    gTimerTickCount += 1;
  }

}



/*
Maintains a set of AO
Click on item for popup menu
- resume AO
- request single animation
- request permanent animation (until resume AO)

Layout in object of files:

animator (script)
'AO '<AO name>
<anim name>

'AO ' prefix is reserved to AOs
a standalone anim can be requested instead

Some mappings can also be made for AOs in case one cannot rename the anim files.
Here can be defined in the map as <supposed file name> -> <file name in object>

AO names:
"Crouching" State   crouch
"CrouchWalking" State   crouchwalk
"Falling Down"  State   falldown
"Flying"  State   fly
"FlyingSlow"  State   flyslow
"Hovering"  State   hover
"Hovering Down" State   hover_down
"Hovering Up" State   hover_up
"Jumping" State While still in the air during a jump. jump
"Landing" Transition  When landing from a jump. land
"PreJumping"  Transition  At the beginning of a jump. prejump
"Running" State   run
"Sitting" State Sitting on an object (and linked to it).  sit
"Sitting on Ground" State Sitting, but not linked to an object.[1]  sit_ground_constrained
"Standing"  State   stand
"Standing Up" Transition  After falling a great distance. Sometimes referred to as Hard Landing.  standup
"Striding"  State When the avatar is stuck on the edge of an object or on top of another avatar.  stride
"Soft Landing"  Transition  After falling a small distance. soft_land
"Taking Off"  State   hover_up
"Turning Left"  State   turnleft
"Turning Right" State   turnright
"Walking" State   walk


Init animation
The animation init if present will be started at attach moment.
If the init animation is present, AOs will be IGNORED.

The AO Standing animation is the only one that needs to be numbered and is capable of cycling.

Example inv names:

init
AO Flying
AO Sitting
AO Standing1
AO Standing2
AO Standing3
My wonderful animation
Wings folded

*/