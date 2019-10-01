
!Button show in the below order. Note: The .Show() returns the Equate 1,2,4 and not 1,2,3,4
TD_BTN:OK         EQUATE(01)  !return value 1 TD_ID_OK SDK: IDOK     SDK: TDCBF_OK_BUTTON     !Changed Equates slightly from SDK
TD_BTN:YES        EQUATE(02)  !return value 6 TD_ID_YES     IDYES         TDCBF_YES_BUTTON   
TD_BTN:NO         EQUATE(04)  !return value 7 TD_ID_NO      IDNO          TDCBF_NO_BUTTON    
TD_BTN:RETRY      EQUATE(16)  !return value 4 TD_ID_RETRY   IDRETRY       TDCBF_CANCEL_BUTTON
TD_BTN:CANCEL     EQUATE(08)  !return value 2 TD_ID_CANCEL  IDCANCEL      TDCBF_RETRY_BUTTON 
TD_BTN:CLOSE      EQUATE(32)  !return value 8 TD_ID_CLOSE   IDCLOSE       TDCBF_CLOSE_BUTTON 
!UNDOCUMENTED Buttons. These are on MessageBox() and work on TaskDialog but MSDN does not document
TD_BTN:Abort      EQUATE( 10000h)  !return value  3 TD_ID_ABORT     Btw No     & Retry
TD_BTN:Ignore     EQUATE( 20000h)  !return value  5 TD_ID_IGNORE    Btw Cancel & TryAgain
TD_BTN:TryAgain   EQUATE( 40000h)  !return value 10 TD_ID_TRYAGAIN  Btw Ignore & Continue
TD_BTN:Continue   EQUATE( 80000h)  !return value 11 TD_ID_CONTINUE  Btw TryAgn & Close
!na TD_BTN:Help       EQUATE(100000h)  !does NOT return value       Last after Close
TD_ButtonMask     EQUATE(0F003Fh)  !All Common 3Fh and Undocumented 1F0000h w/o Help 0F0000h

!The dialog returns Button Pressed as ID Numbers and NOT the Bitmap in the call (like Clarion)
TD_ID_OK     EQUATE(1) !If pressed TD_BTN:OK     !1 IDOK     Changed Equates slightly from SDK
TD_ID_YES    EQUATE(6) !If pressed TD_BTN:YES    !6 IDYES
TD_ID_NO     EQUATE(7) !If pressed TD_BTN:NO     !7 IDNO
TD_ID_RETRY  EQUATE(4) !If pressed TD_BTN:RETRY  !4 IDRETRY
TD_ID_CANCEL EQUATE(2) !If pressed TD_BTN:CANCEL !2 IDCANCEL also for TD_Flag_ALLOW_DIALOG_CANCELLATION
TD_ID_CLOSE  EQUATE(8) !If pressed TD_BTN:CLOSE  !8 IDCLOSE
TD_ID_Abort    EQUATE(3)  !Undocumented    
TD_ID_Ignore   EQUATE(5)  !Undocumented
TD_ID_TryAgain EQUATE(10) !Undocumented
TD_ID_Continue EQUATE(11) !Undocumented
!na TD_ID_Help    EQUATE(9)  !Undocumented. Never Returned.

!region TaskDialog Icon Equates  
                        !MAKEINTRESOURCEW(-1)=65536-1
TD_ICON_BLANK           EQUATE(0)          !No Icon, maybe there is a blank
TD_ICON_WARNING         EQUATE(0FFFFh+1-1) !(!) Exclamation yellow triangle. (same image as IDI_EXCLAMATION)   SDK was TD_WARNING_ICON     MAKEINTRESOURCEW(-1)
TD_ICON_ERROR           EQUATE(0FFFFh+1-2) !(X) A red circle "x" or  stop-sign or. (same as IDI_HAND)          SDK was TD_ERROR_ICON       MAKEINTRESOURCEW(-2)
TD_ICON_INFORMATION     EQUATE(0FFFFh+1-3) !(i) A blue circle "i". (same image as IDI_ASTERISK was * in 3.1)   SDK was TD_INFORMATION_ICON MAKEINTRESOURCEW(-3)
TD_ICON_SHIELD          EQUATE(0FFFFh+1-4) !Vista Security Shield (blue and yellow corners)                    SDK was TD_SHIELD_ICON      MAKEINTRESOURCEW(-4)
TD_ICON_SHIELD_BLUE     EQUATE(0FFFFh+1-5) !Vista Security shield,           main text on Blue background
TD_ICON_SHIELD_WARNING  EQUATE(0FFFFh+1-6) !(!)Exclamation in Yellow Shield main text on Orange background
TD_ICON_SHIELD_ERROR    EQUATE(0FFFFh+1-7) !X in Shield                     main text on Red background
TD_ICON_SHIELD_OK       EQUATE(0FFFFh+1-8) !Checkmark in Green Shield       main text on green background
TD_ICON_SHIELD_GRAY     EQUATE(0FFFFh+1-9) !same image as SHIELD ICON       main text on medium gray background
TD_ICON_IDI_QUESTION    EQUATE(32514)      !(?) Question mark in circle. IDI_QUESTION. Deprecated by Microsoft
TD_ICON_IDI_APPLICATION EQUATE(32512)      !Application window icon. IDI_APPLICATION MAKEINTRESOURCE(32512). Same as IDI_WINLOGO
!TD_ICON_IDI_HAND        EQUATE(32513)      !IDI_HAND is TD_ICON_ERROR
!TD_ICON_IDI_EXCLAMATION EQUATE(32515)      !IDI_EXCLAMATION is TD_ICON_WARNING
!TD_ICON_IDI_ASTERISK    EQUATE(32516)      !IDI_ASTERISK
!no TD_ICON_IDI_WINLOGO     EQUATE(32517)      !IDI_WINLOGO

!endregion TaskDialog Icon Equates 

TD_HR:E_OUTOFMEMORY   EQUATE(8007000Eh)  !-2147483646
TD_HR:E_INVALIDARG    EQUATE(80070057h)  !-2147024809
TD_HR:E_FAIL          EQUATE(80004005h)  !-2147483640
!TD_HR:E_INVALIDARG    EQUATE(80070057h)  !-2147024809
!  Message('TD_HR:E_OUTOFMEMORY ' &  TD_HR:E_OUTOFMEMORY & '|TD_HR:E_INVALIDARG ' &  TD_HR:E_INVALIDARG & |
!          '|TD_HR:E_FAIL ' &  TD_HR:E_FAIL ) 

!region TaskDialog Structures 
CBTaskDialogConfigType  GROUP,TYPE !struct _TASKDIALOGCONFIG {                      d=done
cbSize                    UNSIGNED               !UINT cbSize =SIZE() 96 bytes      d  TDCfg:cbSize                 
hwndParent                SIGNED                 !HWND really hwnd Owner             TDCfg:hwndParent             
hInstance                 SIGNED                 !HINSTANCE hInstance                TDCfg:hInstance              
dwFlags                   LONG                   !TASKDIALOG_FLAGS dwFlags           TDCfg:dwFlags                
dwCommonButtons           LONG                   !TASKDIALOG_COMMON_BUTTON_FLAGS   d  TDCfg:dwCommonButtons        
pszWindowTitle            LONG !PCWSTR           !PCWSTR pszWindowTitle            d  TDCfg:pszWindowTitle         
hMainIcon                 SIGNED                 !HICON hMainIcon                    TDCfg:hMainIcon              
pszMainIcon               LONG,OVER(hMainIcon)   !PCWSTR pszMainIcon                 TDCfg:pszMainIcon            
pszMainInstruction        LONG !PCWSTR           !PCWSTR pszMainInstruction        d  TDCfg:pszMainInstruction     
pszContent                LONG !PCWSTR           !PCWSTR pszContent                d  TDCfg:pszContent             
cButtons                  UNSIGNED  !Count pBtn  !UINT cButtons                    d  TDCfg:cButtons               
pButtons                  UNSIGNED               !TASKDIALOG_BUTTON *pButtons      d  TDCfg:pButtons               
nDefaultButton            SIGNED                 !int nDefaultButton               d  TDCfg:nDefaultButton         
cRadioButtons             UNSIGNED               !UINT cRadioButtons               d  TDCfg:cRadioButtons          
pRadioButtons             UNSIGNED               !TASKDIALOG_BUTTON *pRadioButtons d  TDCfg:pRadioButtons          
nDefaultRadioButton       SIGNED                 !int nDefaultRadioButton          d  TDCfg:nDefaultRadioButton    
pszVerificationText       LONG !PCWSTR           !PCWSTR pszVerificationText       d  TDCfg:pszVerificationText    
pszExpandedInformation    LONG !PCWSTR           !PCWSTR pszExpandedInformation    d  TDCfg:pszExpandedInformation 
pszExpandedControlText    LONG !PCWSTR           !PCWSTR pszExpandedControlText    d  TDCfg:pszExpandedControlText 
pszCollapsedControlText   LONG !PCWSTR           !PCWSTR pszCollapsedControlText   d  TDCfg:pszCollapsedControlText
hFooterIcon               SIGNED                 !HICON hFooterIcon                d  TDCfg:hFooterIcon            
pszFooterIcon             LONG,OVER(hFooterIcon) !PCWSTR pszFooterIcon             d  TDCfg:pszFooterIcon          
pszFooter                 LONG !PCWSTR           !PCWSTR pszFooter                 d  TDCfg:pszFooter              
pfCallback                LONG                   !PFTASKDIALOGCALLBACK pfCallback  d  TDCfg:pfCallback             
lpCallbackData            SIGNED                 !LONG_PTR lpCallbackData          d  TDCfg:lpCallbackData         
cxWidth                   UNSIGNED               !UINT cxWidth                     d  TDCfg:cxWidth                
                                                                                 
    END
!endregion TaskDialog Structures

!region TaskDialog Flag Equates
!TDF_ in SDK renamed here as TD_Flag_   enum _TASKDIALOG_FLAGS
TD_Flag_ENABLE_HYPERLINKS               EQUATE(0001h) !Requires CALLBACK  See TaskDialogCallbackProc. Enables hyperlink in text as <A HREF="executablestring">Hyperlink Text</A>
TD_Flag_USE_HICON_MAIN                  EQUATE(0002h) !Use icon handle in hMainIcon as the primary icon in the task dialog. If this flag is specified, the pszMainIcon member is ignored.
TD_Flag_USE_HICON_FOOTER                EQUATE(0004h) !Use icon in the hFooterIcon member as the footer icon in the task dialog. If this flag is specified, the pszFooterIcon member is ignored.
TD_Flag_ALLOW_DIALOG_CANCELLATION  EQUATE(0008h) !DD.Flag.CancelAllowed=1    !Can close using Alt-F4, Escape, and the title bar's close button even if no cancel button is specified in dwCommonButtons or pButtons members.

TD_Flag_USE_COMMAND_LINKS          EQUATE(0010h) !DD.ButtonCmdLinks=1   member are displayed as command links (using a standard task dialog glyph) instead of push buttons. 
TD_Flag_USE_COMMAND_LINKS_NO_ICON  EQUATE(0020h) !DD.ButtonCmdLinks=2   Same as TD_Flag_USE_COMMAND_LINKS without Icons
!The first new line <10> character in the pszButtonText member will be treated as the command link's main text,
!and the remainder will be treated as the command link's note. Do NOT use <13,10> or you get 2 LF

TD_Flag_EXPAND_FOOTER_AREA         EQUATE(0040h) !DD.ExpandInFooter=1  pszExpandedInformation is displayed at the bottom of the dialog footer area instead of immediately after the dialog's content. 
TD_Flag_EXPANDED_BY_DEFAULT        EQUATE(0080h) !DD.ExpandByDefault=1 pszExpandedInformation is displayed when the dialog is initially displayed.
TD_Flag_VERIFICATION_FLAG_CHECKED  EQUATE(0100h) !DD.CheckboxChecked=1 Verification checkbox on dialog is checked when dialog is initially displayed. Ignored if the pszVerificationText NULL
TD_Flag_SHOW_PROGRESS_BAR          EQUATE(0200h) !A Progress Bar is to be displayed.         N/A Req callback on TDN_TIMER   send TDM_SET_PROGRESS_BAR_POS
TD_Flag_SHOW_MARQUEE_PROGRESS_BAR  EQUATE(0400h) !A Marquee Progress Bar is to be displayed. N/A Req callback on TDN_CREATED send TDM_SET_PROGRESS_BAR_MARQUEE 
TD_Flag_CALLBACK_TIMER                  EQUATE(0800h) !task dialog's callback is to be called approximately every 200 milliseconds.

TD_Flag_POSITION_RELATIVE_TO_WINDOW  EQUATE(1000h) !DD.Flag.Position2Window=1  Centers dialog over hwndParent, else centered on Monitor
TD_Flag_RTL_LAYOUT                   EQUATE(2000h) !DD.Flag.Right2Left=1  text is displayed reading right to left.
TD_Flag_NO_DEFAULT_RADIO_BUTTON      EQUATE(4000h) !DD.RadioDefaultID=-1     no default item will be selected.
TD_Flag_CAN_BE_MINIMIZED             EQUATE(8000h) !DD.Flag.Minimizable the task dialog can be minimized.
TD_Flag_NO_SET_FOREGROUND           EQUATE(10000h) !DD.Flag.NoSetForeground  Don't call SetForegroundWindow() when activating the dialog Windows 8 or newer
TD_Flag_SIZE_TO_CONTENT           EQUATE(1000000h) !DD.Flag.Size2Content=1   (uses ellipses less for long strings) width of dialog is determined by the width of its content area. Ignored if cxWidth is not set to 0.// used by ShellMessageBox to emulate MessageBox sizing behavior
!TDF_ in SDK renamed here as TD_Flag_   
!endregion TaskDialog  Flag Equates       !These were renamed from TDF_ to TD_Flag_
    OMIT('**END**')


    !end of OMIT('**END**')
