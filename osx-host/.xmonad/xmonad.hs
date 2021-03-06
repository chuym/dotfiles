import XMonad

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks

import XMonad.Prompt
import XMonad.Prompt.Shell

import qualified XMonad.Util.ExtensibleState as XS
import XMonad.Util.Loggers
import XMonad.Util.Run
import XMonad.Util.Timer

import Control.Concurrent

import System.Exit

import qualified Data.Map as M
import Data.Monoid

--------------------------------------------------------------------------------------------
-- LOOK AND FEEL
--------------------------------------------------------------------------------------------

homeDir = "/home/chuym/.xmonad"
myFont = "Dina:style=Regular:size=9"
boxleftIcon = homeDir ++ "/icons/boxleft.xbm"

myBGColor = "#0b0f18"
myFGColor = "#6e9ff4" -- Main Color
myBGUrgenColor = "#f4c36e"
myFGUrgenColor = "#18130b"


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
			io (exitWith ExitSuccess)
		killAndRestart =
			(spawn "/usr/bin/killall dzen2") <+>
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
    { ppCurrent          = dzenColor myBGColor myFGColor . wrap "[" "]"
    , ppHidden           = dzenColor myFGColor myBGColor . wrap "[" "]"
    , ppHiddenNoWindows  = dzenColor myFGColor myBGColor . wrap " " " "
    , ppUrgent           = dzenColor myFGColor myBGUrgenColor . wrap "[" "]"
    , ppTitle            = dzenColor myFGColor myBGColor . wrap ("^i(" ++ boxleftIcon ++ ")") " "
    , ppLayout           = dzenColor myFGColor myBGColor . wrap "|| " " ||"
    }

--------------------------------------------------------------------------------------------
-- STATUSBAR
--------------------------------------------------------------------------------------------

myStatusBarHook h = dynamicLogWithPP dzenPP
    { ppOutput = hPutStrLn h
    , ppOrder  = \(_:_:_:x) -> x
    , ppSep    = " "
    , ppExtras = [ myStatusBarData ]
    }

myStatusBarData = logCmd "cat /tmp/xmonad.status"

--------------------------------------------------------------------------------------------
-- SHELL PROMPT
--------------------------------------------------------------------------------------------

myXPConfig = defaultXPConfig
	{ font              = "xft:" ++ myFont
	, bgColor           = myBGColor
	, fgColor           = myFGColor
	, bgHLight          = myFGColor
	, fgHLight          = myBGColor
	, borderColor       = myBGColor
	, promptBorderWidth = 1
	, height            = 18
	, position          = Top
	, historySize       = 100
	, historyFilter     = deleteConsecutive
	, autoComplete      = Nothing
	}


--------------------------------------------------------------------------------------------
-- DZEN BARS DEFINITION
--------------------------------------------------------------------------------------------

myTaskBar   = "dzen2 -x '0' -w '1000' -ta 'l' -fn '" ++ myFont ++ "' -h '18'"
    ++ " -bg '" ++ myBGColor ++ "' -fg '" ++ myFGColor ++ "'"

myStatusBar = "dzen2 -x '1000' -w '440' -ta 'r' -fn '" ++ myFont ++ "' -h '18'"
    ++ " -bg '" ++ myBGColor ++ "' -fg '" ++ myFGColor ++ "'"

--------------------------------------------------------------------------------------------
-- MAIN                                                                                   --
--------------------------------------------------------------------------------------------

main = do
    taskbar   <- spawnPipe myTaskBar
    statusbar <- spawnPipe myStatusBar
    xmonad defaultConfig
		{ terminal           = "/usr/bin/urxvt" 
		, modMask            = mod1Mask          --mod1Mask is Alt, mod4mask is winkey
        , borderWidth        = 1
        , focusedBorderColor = myFGColor
        , focusFollowsMouse  = False
        , keys               = myKeys <+> keys defaultConfig
        , startupHook        = myStartupHook
        , handleEventHook    = myHandleEventHook
        , layoutHook         = myLayoutHook
        , manageHook         = myManageHook
        , logHook            = myTaskbarHook taskbar 
            <+> myStatusBarHook statusbar
		}
