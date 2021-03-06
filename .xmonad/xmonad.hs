{-# LANGUAGE DeriveDataTypeable #-}
import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook

import XMonad.Prompt
import XMonad.Prompt.Shell

import qualified XMonad.Util.ExtensibleState as XS
import qualified XMonad.StackSet as W

import XMonad.Util.Loggers
import XMonad.Util.NamedWindows
import XMonad.Util.Run
import XMonad.Util.Timer

import Control.Concurrent

import System.Exit

import qualified Data.Map as M
import Data.Monoid

--------------------------------------------------------------------------------------------
-- Custom datatypes
--------------------------------------------------------------------------------------------

data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

--------------------------------------------------------------------------------------------
-- LOOK AND FEEL
--------------------------------------------------------------------------------------------

homeDir = "/home/xdc/.xmonad"
myFont = "Terminus:style=Regular:size=12"

myBGColor = "#0b0f18"
myActiveColor = "#9d9fa2"
myInactiveColor = "#6c6f74"
myHiddenColor = "#3b3e46"
myBGUrgenColor = "#f4c36e"
myFGUrgenColor = "#18130b"

myFadeAmount = 0.9

--------------------------------------------------------------------------------------------
-- FADE INACTIVE WINDOWS
--------------------------------------------------------------------------------------------

myFadeInactiveHook :: X ()
myFadeInactiveHook = fadeInactiveLogHook myFadeAmount

--------------------------------------------------------------------------------------------
-- STARTUP HOOK
--------------------------------------------------------------------------------------------

-- wrapper for the Timer id, so it can be stored as custom mutable state
data TidState = TID TimerId deriving Typeable

instance ExtensionClass TidState where
    initialValue = TID 0

myStartupHook = startTimer 1 >>= XS.put . TID

--------------------------------------------------------------------------------------------
-- HANDLE EVENT HOOK
--------------------------------------------------------------------------------------------

myHandleEventHook e = do              -- e is the event we've hooked
    (TID t) <- XS.get                 -- get the recent Timer id
    handleTimer t e $ do              -- run the following if e matches the id
        startTimer 2 >>= XS.put . TID -- restart the timer, store the new id
        ask >>= logHook . config      -- get the loghook and run it
        return Nothing                -- return required type
    return $ All True                 -- return required type

--------------------------------------------------------------------------------------------
-- KEYBINDINGS
--------------------------------------------------------------------------------------------

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    [ ((modMask, xK_Return), spawn $ XMonad.terminal conf)
    , ((modMask, xK_q), killAndRestart)
    , ((modMask .|. shiftMask, xK_q), killAndExit)
    , ((modMask, xK_p), shellPrompt myXPConfig)
    ] where
		killAndExit =
			(spawn "/usr/bin/killall dzen2") <+>
			(spawn "/usr/bin/killall xmobar") <+>
			io (exitWith ExitSuccess)
		killAndRestart =
			(spawn "/usr/bin/killall dzen2") <+>
			(spawn "/usr/bin/killall xmobar") <+>
			(liftIO $ threadDelay 1000000) <+>
			(restart "xmonad" True)

--------------------------------------------------------------------------------------------
-- DOCKS AND LAYOUT MANAGEMENT
--------------------------------------------------------------------------------------------

myManageHook = manageDocks

myLayoutHook = avoidStruts ( tall ||| Mirror tall ||| Full )
    where tall = Tall 1 (3/100) (1/2)

--------------------------------------------------------------------------------------------
-- TASKBAR
--------------------------------------------------------------------------------------------

myTaskbarHook h = dynamicLogWithPP $ myTaskbarPP { ppOutput = hPutStrLn h }

myTaskbarPP = dzenPP
    { ppCurrent          = dzenColor myActiveColor myBGColor . wrap " " " "
    , ppHidden           = dzenColor myInactiveColor myBGColor . wrap " " " "
    , ppHiddenNoWindows  = dzenColor myHiddenColor myBGColor . wrap " " " "
    , ppUrgent           = dzenColor myFGUrgenColor myBGUrgenColor . wrap "[" "]"
    , ppTitle            = dzenColor myActiveColor myBGColor . wrap " --->" "<--- "
    , ppLayout           = (\_ -> "")
    }

--------------------------------------------------------------------------------------------
-- STATUSBAR
--------------------------------------------------------------------------------------------

myStatusBarHook h = dynamicLogWithPP xmobarPP
    { ppOutput = hPutStrLn h
    , ppOrder  = \(_:_:_:x) -> x
    , ppSep    = " "
    }

--------------------------------------------------------------------------------------------
-- SHELL PROMPT
--------------------------------------------------------------------------------------------

myXPConfig = defaultXPConfig
	{ font              = "xft:" ++ myFont
	, bgColor           = myBGColor
	, fgColor           = myActiveColor
	, bgHLight          = myActiveColor
	, fgHLight          = myBGColor
	, borderColor       = myBGColor
	, promptBorderWidth = 1
	, height            = 20
	, position          = Top
	, historySize       = 100
	, historyFilter     = deleteConsecutive
	, autoComplete      = Nothing
	}


--------------------------------------------------------------------------------------------
-- DZEN BARS DEFINITION
--------------------------------------------------------------------------------------------

instance UrgencyHook LibNotifyUrgencyHook where
  urgencyHook LibNotifyUrgencyHook w = do
    name <- getName w
    Just idx <- fmap(W.findTag w) $ gets windowset

    safeSpawn "notify-send" [show name, "workspace " ++ idx]

--------------------------------------------------------------------------------------------
-- DZEN BARS DEFINITION
--------------------------------------------------------------------------------------------

myTaskBar   = "dzen2 -x '0' -w '1500' -ta 'l' -fn '" ++ myFont ++ "' -h '20'"
    ++ " -bg '" ++ myBGColor ++ "' -fg '" ++ myActiveColor ++ "'"

--------------------------------------------------------------------------------------------
-- MAIN                                                                                   --
--------------------------------------------------------------------------------------------

main = do
    taskbar   <- spawnPipe myTaskBar
    statusbar <- spawnPipe "xmobar"
    xmonad $ withUrgencyHook LibNotifyUrgencyHook
           $ defaultConfig
		{ terminal           = "/usr/bin/urxvt" 
		, modMask            = mod4Mask          --mod1Mask is Alt, mod4mask is winkey
                , borderWidth        = 1
                , focusedBorderColor = myActiveColor
                , focusFollowsMouse  = False
                , keys               = myKeys <+> keys defaultConfig
                , startupHook        = myStartupHook
                , handleEventHook    = myHandleEventHook
                , layoutHook         = myLayoutHook
                , manageHook         = manageHook defaultConfig <+> myManageHook
                , logHook            = myTaskbarHook taskbar 
                                       <+> myStatusBarHook statusbar
		}
