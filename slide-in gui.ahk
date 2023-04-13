;---------------------------------------------------------------------------------------------------------------------------
; INSTRUCTIONS
;
; By default when starting the script, you will see a transparent area on the right side of the screen indicating
; where the mouse has to be for the gui to slide in. If you don't want this, you have two options:
;
; Option 1: Set transparency property to 1.
; Everything will still be able to operate as intended with no other change.
; However, this doesn't remove the activation area gui, it only makes it barely visible.
; If you're still noticing it when you're not looking for it and don't want it, follow Option 2's instructions.
;
; Option 2: Remove or comment out all lines that mention Activation_Area_Gui.
; This will break the check for the gui so, you will then have to uncomment the alternative check in the MousePosition() method.
;
;
; Extra Info:
; In the MousePosition() method, it starts with a check if the current window is fullscreen. If the active window is fullscreen,
; the gui doesn't slide in. Designed this way because it would trigger during gaming and messed with gameplay. If you still want the
; slide-in gui to function in other fullscreen windows, you can use a hotkey to toggle it on and off for fullscreen apps.
; Example: ^F2::SlideGui.Toggle_Fullscreen_Exception()
; If you don't game, you can probably safely remove this check.
;
; You can even enable and disable the menu altogether with a hotkey.
; Example: ^F1::SlideGui.Toggle_Gui()
;
; Be sure to look at the comments for the properties in case there's something you want to alter to your liking :)
;---------------------------------------------------------------------------------------------------------------------------

#SingleInstance
SetWinDelay(-1)
CoordMode('Mouse')


SlideGui.Create_Gui()


class SlideGui {
    ; properties
    static offsetModifier 	        := 10           ; adjust this number to how fast you want the gui to slide in and out
    static default_text_color       := 'c21e648'  ; starting text color
    static highlighted_text_color   := 'cffffff'  ; color of text when mouse is over it
    static gui_color                := '111111'     ; gui BackColor
    static how_far_from_the_edge    := 30           ; how many pixels within the right side of the screen for the gui to trigger
    static vertical_tolerance       := 50           ; how many pixels above and below the gui will trigger the gui
    static transparency             := 10           ; default transparency of activation area, if you don't want this to be visible, set it to 1 so that this will still function
    static fullscreenException      := false        ; changing this via a hotkey with the Toggle_Fullscreen_Exception() method can let the gui work in fullscreen apps



    ; methods
    static CheckMousePosition       := ObjBindMethod(this, 'MousePosition')
    static CheckIfTextIsUnderCursor := ObjBindMethod(this, 'TextColorChangeOnMouseOver')
    static Slide_Gui_In             := ObjBindMethod(this, 'Slide_In')
    static Slide_Gui_Out            := ObjBindMethod(this, 'Slide_Out')




    ; constanly get mouse position and id of window under the cursor
    ; to determine if if gui should slide in or out
    static MousePosition() {
        ; if app is fullscreen and toggle for exception is false
        if this.Fullscreen() and not this.fullscreenException {
            WinSetTransparent(0, this.Activation_Area_Gui)
            return
        }
         else WinSetTransparent(this.transparency, this.Activation_Area_Gui)


        ; get mouse position and ID of window under the cursor
        MouseGetPos(&mouse_x_position, &mouse_y_position)    ; get position of mouse
        this.Sliding_Gui.GetPos(, &gui_top_position, &guiWidth, &guiHeight)


        ; alternate check if you're removing all traces of Activation_Area_Gui per the instructions at the beginning of the script
        ; if (InTrigger_Area() or this.MouseIsOver(this.Sliding_Gui)) and mouse_x_position < A_ScreenWidth {	; if mouse is over guis, slide in gui

        ; mouse_x_position evaluation here is only because I have a monitor on the right that interfered
        ; with this process if I moved my mouse onto the right monitor where the gui was sliding back to
        if (this.MouseIsOver(this.Sliding_Gui) or this.MouseIsOver(this.Activation_Area_Gui)) and mouse_x_position < A_ScreenWidth {	; if mouse is over guis, slide in gui
            WinSetTransparent(1, this.Activation_Area_Gui)  ; hide trigger area as best as possible
            this.Sliding_Gui.Restore()
            this.Slide_The_Gui_In()
        }

        else this.Slide_The_Gui_Out()


        ; alternative to default check for mouse position
        InTrigger_Area() {	; defines the area the gui will start to slide in
            return mouse_x_position > (A_ScreenWidth - this.how_far_from_the_edge)  ; mouse_x_position is within the last 30 pixels (default) of the screen
            and mouse_x_position < A_ScreenWidth
            and (mouse_y_position > (gui_top_position - this.vertical_tolerance)    ; mouse_y_position is within 50 pixels (default) above and below gui height
            and mouse_y_position < (gui_top_position + guiHeight + this.vertical_tolerance))
        }
    }




    static Slide_In() {
        try this.Sliding_Gui.GetPos(&guiX)
        catch {
            this.Slide_The_Gui_Out()
            return
        }

        if (guiX - this.offsetModifier) <= this.guiFinalPosition  {   ; if new position is equal to the final position, stop sliding
            this.Stop_Sliding_In()
            this.Sliding_Gui.Move(this.guiFinalPosition) ; make sure it's in the final position
        }
        else this.Sliding_Gui.Move(guiX + -this.offsetModifier)       ; determines if adding or subtracting offsetModifier (sliding in vs sliding out)
    }


    static Slide_Out() {
        try this.Sliding_Gui.GetPos(&guiX)
        catch {
            return
        }

        if (guiX + this.offsetModifier) >= A_ScreenWidth {        ; if new position stops at the initial position, stop sliding
            this.Stop_Sliding_Out()
            this.Sliding_Gui.Move(A_ScreenWidth)
            this.Sliding_Gui.Hide()
            WinSetTransparent(this.transparency, this.Activation_Area_Gui)		; show trigger area
        }
        else this.Sliding_Gui.Move(guiX + this.offsetModifier)
    }



;-------------------------------------------------------------------------------
; AUXILLARY METHODS
;-------------------------------------------------------------------------------
    static Toggle_Fullscreen_Exception() => this.fullscreenException := !this.fullscreenException

    ; enable/disable gui
    static Toggle_Gui() {
        static gui_enabled := true
        static transparency := this.transparency

        gui_enabled := !gui_enabled

        if gui_enabled {
            SetTimer(this.CheckMousePosition, 100)
            this.transparency := transparency
            WinSetTransparent(transparency, this.Activation_Area_Gui)
        }
        else {
            SetTimer(this.CheckMousePosition, 0)
            this.Slide_The_Gui_Out
            this.transparency := 0
        }
    }


    static MouseIsOver(WinTitle*) {
        MouseGetPos(,, &hwnd)
        return hwnd = WinExist(WinTitle*)
    }


    static Slide_The_Gui_In() {
        this.Stop_Sliding_Out()
        SetTimer(this.Slide_Gui_In, 10)
    }

    static Slide_The_Gui_Out() {
        this.Stop_Sliding_In()
        SetTimer(this.Slide_Gui_Out, 10)
    }

    static Stop_Sliding_In() => SetTimer(this.Slide_Gui_In, 0)
    static Stop_Sliding_Out() => SetTimer(this.Slide_Gui_Out, 0)


    ; check if window is fullscreen
    static Fullscreen() {
        try	WinGetPos(,, &w, &h, 'A')   ; get window size
        catch {
           return true ; error kept popping up, might have been desktop active issue
        }
        return (w = A_ScreenWidth && h = A_ScreenHeight) ; return true if fullscreen
     }


    ; checks if mouse is over the text in the slide-in gui. if it is, change the color of that text
     static TextColorChangeOnMouseOver(wParam, lParam, msg, hWnd)
     {
         static PrevHwnd := 0
         currControl := GuiCtrlFromHwnd(hWnd)

         if (currControl != PrevHwnd)
         {
             if currControl
                 currControl.SetFont(this.highlighted_text_color)
             else
                 try PrevHwnd.SetFont(this.default_text_color)

             PrevHwnd := currControl
         }
     }


;-------------------------------------------------------------------------------
; SLIDE-IN GUI AND ACTIVATION AREA
;-------------------------------------------------------------------------------
    static Create_Gui() {
        this.Sliding_Gui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
        this.Sliding_Gui.MarginX := 6
        this.Sliding_Gui.MarginY := 6
        this.Sliding_Gui.BackColor := this.gui_color
        this.Sliding_Gui.SetFont('s11 ' this.default_text_color, 'Segoe UI')


        ; Add new/change text controls as needed and use whatever callback function you need
        this.Sliding_Gui.AddText('Center', 'Cut the'    ).OnEvent('Click',  (*) => MsgBox('First option clicked'))
        this.Sliding_Gui.AddText('Center', 'Hardline'   ).OnEvent('Click',  (*) => MsgBox('Second option clicked'))
        this.Sliding_Gui.AddText('Center', 'at the'     ).OnEvent('Click',  (*) => MsgBox('Third option clicked'))
        this.Sliding_Gui.AddText('Center', 'Mainframe'  ).OnEvent('Click',  (*) => MsgBox('Fourth option clicked'))


        ; show gui at start to get the gui width to determine the final position the gui should sit when slid in
        this.Sliding_Gui.Show('x' A_ScreenWidth ' yCenter AutoSize')
            this.Sliding_Gui.GetPos(, &gui_top_position, &guiWidth, &guiHeight)
            this.guiFinalPosition := A_ScreenWidth - guiWidth

        this.RoundedCorners(15)
        this.Sliding_Gui.Hide() ; hide gui


        ; checks if mouse is over the text in the slide-in gui. if it is, change the color of that text
        OnMessage(0x200, this.CheckIfTextIsUnderCursor)
        ;---------------------------------------------------------------------------------------------
        ; this section shows the area the mouse needs to be in for the gui to activate
        ; it automatically expands depending on the amount of text controls
        this.Activation_Area_Gui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border') ; +E0x20')
        this.Activation_Area_Gui.BackColor := 'ffffff'
        this.Activation_Area_Gui.Show('x' A_ScreenWidth - this.how_far_from_the_edge ' y' gui_top_position - this.vertical_tolerance ' yCenter w30 h' guiHeight + (this.vertical_tolerance * 2))
        WinSetTransparent(this.transparency, this.Activation_Area_Gui)  ; barely visible


        SetTimer(this.CheckMousePosition, 100)
    }


    static RoundedCorners(curve) {     ; dynamically rounds the corners of the gui, param is the curve radius as an integer
        this.Sliding_Gui.GetPos(,, &width, &height)
        WinSetRegion('0-0 w' width+20 ' h' height ' r' curve '-' curve, this.Sliding_Gui)
    }
} ;;;;;;;;;;; END OF CLASS ;;;;;;;;;;;
