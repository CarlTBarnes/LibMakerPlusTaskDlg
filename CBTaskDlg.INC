    OMIT('_EndOfInclude_',_IFDef_CBTaskDlg_Inc_)
_IFDef_CBTaskDlg_Inc_  EQUATE(1)
!--------------------------
! CBTaskDlgClass by Carl Barnes - Disclaimer: This does nothing. If a Task Dialog should appear that would be a surprise to me.
! How to Use
!    INCLUDE('CBTaskDlg.INC'),ONCE      ! TskDlg  CLASS(CBTaskDlgClass).
!--------------------------  

    INCLUDE('CBTaskDlgDef.INC'),ONCE 

CBTDBtnQueue     QUEUE,TYPE     !Queue for Custom buttons and Radios
ID                 LONG
Label              STRING(512)  !Should be big enough, could make &STRING or ANY. Only have 2-10 records while dialog is open
                 END    

!----------------- CBTaskDlgClass -----------------
CBTaskDlgClass    CLASS,TYPE,MODULE('CBTaskDlg.CLW'),LINK('CBTaskDlg.CLW',1),DLL(0)   !,_ABCLinkMode_),DLL(_ABCDllMode_)
!
!Properties
!----------

DD          GROUP       !All the Dialog Data in one group so can be CLEAR(DD)   !Was .TDlg
Caption         ANY     !Window Title
Instruction     ANY     !Large Font Main Instruction
Content         ANY     !Message Body Text
ExpandedText    ANY     !Message ExpandedInfo text
ExpandSeeMoreLabel ANY  !Override 'See details'   text next to on Expander Button      If only 1 of SeeMore / SeeLess is
ExpandSeeLessLabel ANY  !Override 'Hide details'  text next to on Collapse Button      specifed then it shows for both.
CheckboxLabel   ANY     !If you want a Check box then specify a Label      pszVerificationText
CheckboxChecked BYTE    !Is it checked on open                             TD_Flag_VERIFICATION_FLAG_CHECKED
FooterText      ANY     !Text to appear in message footer                  pszFooter
BtnsCommon      LONG    ![suggest call Proc Btns_OYNRCL()] Common Button Equates e.g.  TD_BTN:OK YES NO RETRY CANCEL CLOSE - See ButtonAdd() for Custom
BtnsDefaultID   LONG    !Button ID to give focus on open: e.g. TD_ID_CANCEL or TD_ID_NO
RadioDefaultID  LONG    !If < 0 then TD_Flag_NO_DEFAULT_RADIO_BUTTON            nDefaultRadioButton
Icon_Main       LONG    !Main Icon Equate     TD_ICON:xxx TODO Handle
IconFooter      LONG    !Footer Icon Equate   TD_ICON:xxx
Width           USHORT  !Width            cxWide width of the task dialog's client area, in dialog units           
hInstance       SIGNED                 !HINSTANCE hInstance                TDCfg:hInstance   

!TODO ??? change "Size2" to "NO_Size2Content" so by defaul thtta flag is set
Flag            GROUP
ButtonCmdLinks      BYTE    !0=No 1=Yes 2=Yes No Icons  TD_Flag_USE_COMMAND_LINKS or TD_Flag_USE_COMMAND_LINKS_NO_ICON
CancelAllowed       BYTE    !Returns Btn=TD_ID_CANCEL             !TD_Flag_ALLOW_DIALOG_CANCELLATION Can close using Alt-F4, Escape, and the title bar's close button even if no cancel button is specified in dwCommonButtons or pButtons members.
ElevateBtnID        LONG,DIM(2)  !Sends message to this Button to get elevate Icon  TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE
ExpandByDefault     BYTE    !ExpandedInfo is displayed when the dialog is initially displayed                TDF_EXPANDED_BY_DEFAULT
ExpandInFooter      BYTE    !ExpandedInfo is at bottom of footer area instead of after the dialog's content. TDF_EXPAND_FOOTER_AREA
Hyperlinks          BYTE   !Enables hyperlink in text as <A HREF="executablestring">Hyperlink Text</A> TD_Flag_ENABLE_HYPERLINKS in CALLBACK Class does ShellExecute
MarqueeProgress     BYTE                 !MarqueeProgress  TDF_SHOW_MARQUEE_PROGRESS_BAR           
!ProgressBarPos      BYTE  !??? 1-100 is Pos, 255=Marquee !TD_Flag_SHOW_PROGRESS_BAR TDF_SHOW_MARQUEE_PROGRESS_BAR           
Minimizable         BYTE                 !Minimizable      TDF_CAN_BE_MINIMIZED            
NoSetForeground     BYTE                 !                 TD_Flag_NO_SET_FOREGROUND  Windows 8            
Position2Window     BYTE                 !PosRel2Window    TDF_POSITION_RELATIVE_TO_WINDOW            
Right2Left          BYTE                 !Right2Left       TDF_RTL_LAYOUT
!Size2Content        BYTE                 !Size2Content     TDF_SIZE_TO_CONTENT 
Size2ContentOFF     BYTE    !Without Size2Cont tend to get Narrow Dialogs so make it an OFF setting
ShowFallbackTODO    BYTE    !see the Fallback window instead of the TaskDialog 
!TODO Fallback Radios could use Style checkbox, it is a lot of work compared to selecting but nice
                END
Shutdown        GROUP      !see https://stackoverflow.com/questions/51985841/custom-message-box-that-automatically-disappears
Seconds             USHORT      !Close dialog in how many seconds
ButtonID            USHORT      !Shutdown presses what button, usually Cancel
FooterText          STRING(64)  !Footer shows ## + FooterText
                END
Progress        GROUP
!TODO remove the other progress
Marquee             BYTE        !1=Marquee else Normal and specify Bar_Pos and State
Bar_Pos             BYTE        !1 to 100. This will not change. Not for Marquee. Must be 1 to see it.
State               BYTE        !1=Normal  2=Error (Red) 3=Paused (Yellow)  Not for Marquee.
                END                
            END
Result      GROUP      !Results from last Show
HResult        LONG    !If show failed HR<0. If it worked Returns >=0 Zero
ButtonID       LONG    !ID of Button pressed either TD_ID_Xxx or what you passed in ButtonAdd(ID,Name). It is NOT the TD_BUTTON:Xxx equate 
!could do OYNRCL ?
!n/a work this way ButtonEqt      LONG    !TD_BUTTON:Xxx equate pressed if a Common Button              
RadioID        LONG    !Actual OUT *nButton. The Show() returns TD_BUTTON:Xxx equates
Checked        LONG    !Was Verification Checkbox checked
FallbackUsed   BOOL    !Called Show Fallback Message i.e. the Show must go on
            END
!Methods
!-------
!Init                    PROCEDURE(<STRING Instruction>,<STRING Content>,<STRING Caption>,<LONG Icon>,<LONG BtnsCommon>)     !CLEARS(TDlg)
Init                    PROCEDURE(<STRING Instruction_1>,<STRING Content_2>,<STRING Caption_3>,<LONG Icon_4>,<STRING Btns_OYNRCL_5>,<STRING Default_TDBtn_OrOYNRCL_6>)     !CLEARS(TDlg)
Kill                    PROCEDURE()
Show                    PROCEDURE(<LONG ForceHndOwner>),VIRTUAL,LONG,PROC  !Returns TD_Button:Xxx and sets Shw. group
ShowMessage             PROCEDURE(),VIRTUAL,LONG,PROC   !If TaskDialog Not present this shows a message
VerifyForShow           PROCEDURE(*CBTaskDialogConfigType InOutTDCfg),VIRTUAL  !!Developer can derive and override config

Proc_4                  PROCEDURE(),VIRTUAL
Proc_5                  PROCEDURE(),VIRTUAL

!Use Pipe | or <13,10> or <10> for a Line Break. Only works in Command Links Buttons and Radios
Btns_OYNRCL     PROCEDURE(STRING Ok_Yes_No_Retry_Cancel_cLose, <STRING Default_OYNRCL>) !Set COMMON Btns with a string e.g. 'YSC'=Yes No Cancel
BtnCustomAdd    PROCEDURE(LONG IDNumber, STRING LabelText, BOOL IsDefault=0),BOOL,PROC  !Add 1 Custom Button, return False if failed with ID not unique
BtnCustomKill   PROCEDURE()     !Delete all Custom Buttons
RadioAdd        PROCEDURE(LONG IDNumber, STRING LabelText, BOOL IsDefault=0),BOOL,PROC  !Add 1 Radio, return False if failed with ID not unique
!TODO RadioAddPiped   PROCEDURE(STRING PipedLabelText, LONG Default=1)  !Add multiple radios ('First|Two|Last',2) for use by TMsg() wrapper
RadiosKill      PROCEDURE()     !Delete all Radios 
HRefText        PROCEDURE(STRING LinkURL, <STRING PrettyURL>, BYTE TurnOnHyperlinks=1),STRING  !Format URL <A HREF=Link>Pretty<A>
!Properties Internal
!-------------------
DevBugWarn      BYTE                        !Developer Warning Message if spot bug. Still get DebugOut
QBtnQ           &CBTDBtnQueue,PROTECTED     !Buttons
QRdoQ           &CBTDBtnQueue,PROTECTED     !Radios

!Methods Internal
!----------------
Construct               PROCEDURE()
Destruct                PROCEDURE(),VIRTUAL
FlagAdd                 PROCEDURE(*LONG InOutFlags, BOOL InTurnOn, LONG InFlagValue),VIRTUAL !If TurnOnFlag then BOR(InOutFlags,pFlagValue)
FlagRemove              PROCEDURE(*LONG InOutFlags, BOOL InTurnOff, LONG InFlagValue),VIRTUAL !If TurnOffFlag then BAND(InOutFlags,BXOR(-1,pFlagValue)
QBtn_Add                PROCEDURE(CBTDBtnQueue BRQ, LONG pID, *STRING pLabel),BOOL,PROC,PROTECTED,VIRTUAL !Internal Button Add

!BugsReportBugs ( a global way
DevBugsAreReported      PROCEDURE(BOOL TurnOnDevBugReports, BOOL GlobalDefault=0)  !Spot Dev Bugs and Try to warn
!DefectsAreReported      PROCEDURE(BOOL TurnOnBugReports, BOOL GlobalDefault=0)  !Spot Dev Bugs and Try to warn
DevBugReport            PROCEDURE(STRING pBugText),VIRTUAL
DB                      PROCEDURE(STRING Info)  !Debug Output
Test_TaskDialog         PROCEDURE(*CBTaskDialogConfigType pTskDlgConfig),PROTECTED  !Not TDIndirect()
                    END
!=====================================================================

!=====================================================================
    _EndOfInclude_
