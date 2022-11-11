;---------------------------------------------------------------------------------------------------------------------------
; INSTRUCTIONS
; adjust the variables below as you see fit, lines 13-18
; line 40 is where the text controls start, add as needed and change the callback function to whatever function you desire
;---------------------------------------------------------------------------------------------------------------------------

#SingleInstance
SetWinDelay(-1)
CoordMode('Mouse')


; adjust these variables if you prefer different speeds or colors
offsetModifier 	        := 10           ; adjust this number to how fast you want the gui to slide in and out
default_text_color      := 'c87e6fb'  ; starting text color
highlighted_text_color  := 'cea84bb'  ; color of text when mouse is over it
gui_color               := '1d1f21'     ; gui BackColor
how_far_from_the_edge   := 30           ; how many pixels within the right side of the screen for the gui to trigger
vertical_tolerance      := 50           ; how many pixels above and below the gui will trigger the gui
slide_in 		        := false        ; keep track of gui state


InTrigger_Area() {	; defines the area the gui will start to slide in
	return mouse_x_position > (A_ScreenWidth - how_far_from_the_edge) and mouse_x_position < A_ScreenWidth &&                               ; mouse_x_position is within the last 30 pixels of the screen
	(mouse_y_position > (gui_top_position - vertical_tolerance) and mouse_y_position < (gui_top_position + guiHeight + vertical_tolerance))	; mouse_y_position is within 50 pixels above and below gui height
} 

;-------------------------------------------------------------------------------
; SLIDE-IN GUI
;-------------------------------------------------------------------------------
global Slide_In_Gui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
Slide_In_Gui.MarginX := 6
Slide_In_Gui.MarginY := 6
Slide_In_Gui.BackColor := gui_color
Slide_In_Gui.SetFont('s11 ' default_text_color, 'Segoe UI') 



;---------------------------------------------------------------------------------------------
; Add new text controls as needed and use whatever callback function you need
Slide_In_Gui.AddText('Center', 'Cut the').OnEvent('Click', (*) => MsgBox('First option clicked'))
Slide_In_Gui.AddText('Center', 'Hardline').OnEvent('Click', (*) => MsgBox('Second option clicked'))
Slide_In_Gui.AddText('Center', 'at the').OnEvent('Click', (*) => MsgBox('Third option clicked'))
Slide_In_Gui.AddText('Center', 'Mainframe').OnEvent('Click', (*) => MsgBox('Fourth option clicked'))
;---------------------------------------------------------------------------------------------



Slide_In_Gui.Show('x' A_ScreenWidth ' yCenter AutoSize')	; show to get positions

id := WinGetID(Slide_In_Gui)  ; important for knowing if mouse is over gui to keep it open
WinGetPos(, &gui_top_position, &guiWidth, &guiHeight, Slide_In_Gui)  ; get width of gui
guiFinalPosition := A_ScreenWidth - guiWidth + 1	; +0 left a pixel space, +1 fixes that, not sure if v2 bug

RoundedCorners(15)      ; rounded corners
Slide_In_Gui.Hide()	    ; hide at start


OnMessage(0x200, TextColorChangeOnMouseOver)      ; call this function when moving the mouse over the gui



;---------------------------------------------------------------------------------------------
; this section shows the area the mouse needs to be in for the gui to activate
; it automatically expands depending on the amount of text controls
; if you don't want this at all, delete this area and any lines with trigger_area mentioned
trigger_area := Gui('+E0x20 +AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
trigger_area.BackColor := 'ffffff'
trigger_area.Show('x' A_ScreenWidth - how_far_from_the_edge ' y' gui_top_position - vertical_tolerance ' yCenter w30 h' guiHeight + (vertical_tolerance * 2))
WinSetTransparent(5, trigger_area)  ; barely visible
;---------------------------------------------------------------------------------------------


SetTimer(MousePosition, 10)


MousePosition() {
    global
    MouseGetPos(&mouse_x_position, &mouse_y_position, &isGuiWindow)    ; get position of mouse

	; mouse_x_position evaluation here is only because I have a monitor on the right that interfered with this process under the right condition
    if isGuiWindow = id && mouse_x_position < A_ScreenWidth {	; if mouse is over gui, don't check mouse position or slide out gui
		if !slide_in {		; prevents the menu from sliding out if mouse is over it, even when it's already sliding out (slides it back in)
			Slide_In_Gui.Restore()
			trigger_area.Hide()			; hide trigger area
            slide_in := true
            SetTimer(SlideGui, 10)
        }
      return
	}

    if InTrigger_Area() { 	; if mouse is 30 pixels within the right side of the screen
        if !slide_in {
			Slide_In_Gui.Restore()
			trigger_area.Hide()			; hide trigger area
            slide_in := true
            SetTimer(SlideGui, 10)
        }
    }

    else {
        if slide_in {
			trigger_area.Restore()		; show trigger area
            slide_in := false
            SetTimer(SlideGui, 10)
        }
    }   
}


SlideGui() {
    global
    try WinGetPos(&guiX,,,, Slide_In_Gui)
	catch {
		SetTimer(SlideGui, 0)
		slide_in := false
		return
	}
    
    if slide_in {
		if (guiX - offsetModifier) = guiFinalPosition  {   ; if new position is equal to the final position, stop sliding
            SetTimer(SlideGui, 0)
			WinMove(guiFinalPosition,,,, Slide_In_Gui)   ; determines if adding or subtracting offsetModifier (sliding in vs sliding out)
        }
      
        else if (guiX - offsetModifier) < guiFinalPosition  {                 ; if new position exceeds the final position, adjust it to the final position
          SetTimer(SlideGui, 0)
          WinMove(guiFinalPosition,,,, Slide_In_Gui)
        }
		else
			WinMove(guiX + -offsetModifier,,,, Slide_In_Gui)   ; determines if adding or subtracting offsetModifier (sliding in vs sliding out)
    }

    else {
        if (guiX + offsetModifier) = A_ScreenWidth {    ; if new position stops at the initial position, stop sliding
            SetTimer(SlideGui, 0)
			WinMove(A_ScreenWidth,,,, Slide_In_Gui)   ; determines if adding or subtracting offsetModifier (sliding in vs sliding out)
            Slide_In_Gui.Hide()
		}
		else if (guiX + offsetModifier) > A_ScreenWidth {                ; if new position exceeds the initial position, adjust it to the initial position
			SetTimer(SlideGui, 0)
            WinMove(A_ScreenWidth,,,, Slide_In_Gui)
            Slide_In_Gui.Hide()
		}
		else
			WinMove(guiX + offsetModifier,,,, Slide_In_Gui)   ; determines if adding or subtracting offsetModifier (sliding in vs sliding out)
    }
}

RoundedCorners(curve) {     ; dynamically rounds the corners of the gui, param is the curve radius as an integer
    WinGetPos(,, &width, &height, Slide_In_Gui)
    width   := 'w' width
    height  := 'h' height
    WinSetRegion('0-0 ' width ' ' height ' r' curve '-' curve, Slide_In_Gui)
}


TextColorChangeOnMouseOver(wParam, lParam, msg, Hwnd)
{   
    static PrevHwnd := 0
    currControl := GuiCtrlFromHwnd(Hwnd)

    if (currControl != PrevHwnd) 
    {
        if currControl 
            currControl.SetFont(highlighted_text_color)
        else 
            try PrevHwnd.SetFont(default_text_color)

        PrevHwnd := currControl
    }
}