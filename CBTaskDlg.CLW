                    MEMBER()
!--------------------------
! CBTaskDlgClass by Carl Barnes
!
!--------------------------
DBdev   EQUATE(1)           !Todo make Global 
    INCLUDE('EQUATES.CLW')
    INCLUDE('CBTaskDlg.INC'),ONCE
    INCLUDE('CBWString.INC'),ONCE
PCWSTR      EQUATE(LONG)                 !Pointer to a WStr

MaxDlgBtns  EQUATE(40)      !absurd but 40 should be enough and just 320 bytes of temp use
DlgBtnsType GROUP,TYPE                  !Button and Radio data needed to call API
cButtons        LONG                    !UINT  cButtons;
pButton         GROUP,DIM(MaxDlgBtns)   !TASKDIALOG_BUTTON   *pButtons 
nButtonID           LONG                !  int    nButtonID;
pszButtonText       LONG                !  PCWSTR pszButtonText;
                END
            END

CallBackRefDataTYPE GROUP,TYPE
Magic           LONG                !Is Address of this data, seemed like a good safety check
TskDlgCls       &CBTaskDlgClass     !i.e. Me Self when caller
TDCfgData       LONG !&CBTaskDialogConfigType
TimerReset      BOOL
TimerLast       LONG
         END 

    MAP
QBtn2DlgBtns            PROCEDURE(CBWStrFactoryClass WFactoryCls,CBTDBtnQueue BRQ, DlgBtnsType DlgBtns, BYTE pCan1310 )    
MakeWString             PROCEDURE(CBWStrFactoryClass WFactoryCls, *ANY AnyStr),LONG !Convert ANY to STRING and
MakeWString             PROCEDURE(CBWStrFactoryClass WFactoryCls, STRING Str),LONG !Convert STRING to WStr if Not Blank 
IconIsDefective         PROCEDURE(BOOL IsFooter, *LONG Cfg_hIcon, *LONG Cfg_Flags),BOOL  !True=Bad and Zeros hIcon
ButtonID2Equate         PROCEDURE(LONG ButtonID),LONG       !TaskDialog returns ID 1,2,3 so convert to Equates passed
ButtonEquate2ID         PROCEDURE(LONG TD_Btn:Equate),LONG  !Take ID_Btn: Equate and return button
HResultName             PROCEDURE(LONG pHR),STRING 
Hex8                    PROCEDURE(LONG _Lng),STRING
TimeFmt                 PROCEDURE(LONG pSecs),STRING
IsBadPointer            PROCEDURE(LONG pPtr),BOOL
BWStr                   PROCEDURE(*BSTRING BS, BYTE NullIfBlank=0, BYTE NullIfLenZero=0),LONG !Returns a PWSTR of the BSTR 
BStrFromPWStr           PROCEDURE(*BSTRING OutBS, LONG InPWStr),BOOL !Returns BSTR Set = PWSTR (a copy of it). Returns False if failed
TaskDialogCALLBACK      PROCEDURE(SIGNED hWnd, UNSIGNED NotifyNo, UNSIGNED wParam, SIGNED lParam, SIGNED lpRefData ),LONG,PROC,PASCAL

    module('Win32')
        OutputDebugString(*cstring dMsg),PASCAL,RAW,NAME('OutputDebugStringA'),dll(1)
        ODBWStr(LONG WStrMsg),PASCAL,RAW,NAME('OutputDebugStringW'),dll(1)
        GetLastError(),LONG,PASCAL,DLL(1)         
    !    InitCommonControlsEx(UNSIGNED picce),PASCAL,DLL(1),RAW,BOOL! ?,name('InitCommonControlsExA')
        SendMessageW(SIGNED hWnd, UNSIGNED Msg, UNSIGNED wParam, SIGNED lParam ),SIGNED,PROC,PASCAL,DLL(1)
        ShellExecuteW(SIGNED hwnd=0, LONG lpOperation, LONG lpFile, LONG lpParameters=0, LONG lpDirectory=0, SIGNED nShowCmd=0),SIGNED,PROC,RAW,PASCAL,DLL(1) !Most Unicode LPCW STR
        SysReAllocString(LONG BSTR_pbstr, LONG OLECHAR_psz),SIGNED,RAW,PASCAL,DLL(1)

!https://docs.microsoft.com/en-us/windows/desktop/api/Commctrl/nf-commctrl-taskdialog
TaskDialog    PROCEDURE( |                                      !HRESULT TaskDialog(
    SIGNED              hwndOwner                 , |               !HWND hwndOwner,
    SIGNED              hInstance                 , |               !HINSTANCE hInstance (for Icon Resource)
    PCWSTR              pszWindowTitle            , |               !PCWSTR pszWindowTitle,
    PCWSTR              pszMainInstruction        , |               !PCWSTR pszMainInstruction,
    PCWSTR              pszContent                , |               !PCWSTR pszContent,
    LONG  dwCommonButtons  , |            !TASKDIALOG_COMMON_BUTTON_FLAGS dwCommonButtons,
    PCWSTR              pszIcon                   , |               !PCWSTR pszIcon,
    *SIGNED             pnButton                    |               !int *pnButton
    ),PASCAL,DLL(1),RAW,LONG!,NAME('TaskDialog_fn')   !This is W Unicode only
    !Returns  HRESULT of S_OK or E_FAIL etc

!https://docs.microsoft.com/en-us/windows/desktop/api/Commctrl/nf-commctrl-taskdialogindirect
TaskDialogIndirect    PROCEDURE( |                    !HRESULT TaskDialog Indirect(
    *CBTaskDialogConfigType  pTaskConfig            , | !const TASKDIALOGCONFIG *pTaskConfig,
    <*SIGNED             pnButton                  >, | !int *pnButton,      - Button number or ID pressed
    <*SIGNED             pnRadioButton             >, | !int *pnRadioButton  - Radio ID selected
    <*BOOL               pfVerificationFlagChecked >  | !BOOL *pfVerificationFlagChecked - Was Checkbox checked
    ),PASCAL,DLL(1),RAW,LONG

        END
    END !map   

GLO:DevBugWarn     BOOL

!----------------------------------------
CBTaskDlgClass.Construct        PROCEDURE()
!----------------------------------------
    CODE
    IF (SELF.QBtnQ &= NULL) THEN SELF.QBtnQ &= NEW CBTDBtnQueue.    
    IF (SELF.QRdoQ &= NULL) THEN SELF.QRdoQ &= NEW CBTDBtnQueue.
    SELF.DevBugWarn = GLO:DevBugWarn
    RETURN

!---------------------------------------
CBTaskDlgClass.Destruct PROCEDURE()
!---------------------------------------
    CODE
    IF NOT (SELF.QBtnQ &= NULL)  THEN
       SELF.BtnCustomKill()
       DISPOSE(SELF.QBtnQ)
    END
    IF NOT (SELF.QRdoQ &= NULL)  THEN
       SELF.RadiosKill()
       DISPOSE(SELF.QRdoQ)
    END    
    RETURN
        
!-----------------------------------
!CBTaskDlgClass.Init     PROCEDURE(<STRING pInstruction>,<STRING pContent>,<STRING pCaption>,<LONG pIcon>,<LONG pButtons>)
CBTaskDlgClass.Init PROCEDURE(<STRING pInstruction>,<STRING pContent>,<STRING pCaption>,<LONG pIcon>,<STRING pBtns_OYNRCL>,<STRING pDefaultBtn>)
!-----------------------------------
Def_OYNRCL      STRING(1)
    CODE
    CLEAR(SELF.DD) 
    CLEAR(SELF.Result)
    SELF.BtnCustomKill() 
    SELF.RadiosKill() 
    IF DBdev THEN Self.DB('.Init').
    IF ~OMITTED(pCaption   ) THEN SELF.DD.Caption    = pCaption   .
    IF ~OMITTED(pInstruction) THEN SELF.DD.Instruction = pInstruction.
    IF ~OMITTED(pContent   ) THEN SELF.DD.Content    = pContent   .
    IF ~OMITTED(pIcon      ) THEN SELF.DD.Icon_Main  = pIcon   . 
    IF ~OMITTED(pDefaultBtn) THEN                 !The Default can be a 
        IF NUMERIC(pDefaultBtn) THEN              !Was ID Number passed
           SELF.DD.BtnsDefaultID=ButtonEquate2ID(pDefaultBtn)
        ELSE
           Def_OYNRCL=pDefaultBtn                 !Was OYNRCL
        END 
    END 
    IF ~OMITTED(pBtns_OYNRCL) THEN 
        IF NUMERIC(pBtns_OYNRCL) THEN 
           SELF.DD.BtnsCommon = pBtns_OYNRCL
        ELSE
           SELF.Btns_OYNRCL(pBtns_OYNRCL, Def_OYNRCL)
        END
    END 
    RETURN

!-----------------------------------
CBTaskDlgClass.Kill     PROCEDURE()
!-----------------------------------
    CODE
    RETURN

!----------------------------------------------------------------------
CBTaskDlgClass.Show PROCEDURE(<LONG ForceHndOwner>)!,VIRTUAL,LONG,PROC
!----------------------------------------------------------------------
WStrFactory CBWStrFactoryClass
dwFLAGS         &LONG   !Will &= TDCfg:dwFlags to shorted some code TASKDIALOG_FLAGS
!HaveCheckbox    BOOL    !if Checkbox Label is specified then get one
!fChecked        BOOL    !aka fVerificationFlagChecked

Buttons         GROUP(DlgBtnsType).          
Radios          GROUP(DlgBtnsType).
!nButton         SIGNED   !TD returns 1,2,3,4,5
!nRadioButton    SIGNED   !TD returns ID Number 

ButtonEqt       SIGNED   !This reports TD_BUTTON:Xxx equate
HR              SIGNED
X               SIGNED,AUTO
TDConfig        GROUP(CBTaskDialogConfigType),PRE(TDCfg)
                END
BackData        GROUP(CallBackRefDataTYPE)
                END
DoCallBack      BYTE                
    CODE
    dwFLAGS &= TDCfg:dwFlags
    CLEAR(TDConfig)  ;  TDCfg:cbSize = SIZE(CBTaskDialogConfigType)
    CLEAR(SELF.Result)

    TDCfg:hwndParent        = CHOOSE(~OMITTED(ForceHndOwner),0{PROP:Handle},ForceHndOwner)
    TDCfg:hInstance         = SELF.dd.hInstance
    TDCfg:pszWindowTitle    = MakeWString(WStrFactory, SELF.DD.Caption)   
    TDCfg:pszMainInstruction = MakeWString(WStrFactory, SELF.DD.Instruction)
    TDCfg:pszContent        = MakeWString(WStrFactory, SELF.DD.Content)
    TDCfg:dwCommonButtons   = BAND(SELF.DD.BtnsCommon,TD_ButtonMask)  !Invalid buttons show no msg in Win 10 (silent crash see events), but in Win 7 caused Exception code C0000005: Access Violation!
    TDCfg:pszMainIcon       = SELF.DD.Icon_Main

    IF SELF.DD.ExpandedText THEN
       TDCfg:pszExpandedInformation  = MakeWString(WStrFactory, SELF.DD.ExpandedText)
       TDCfg:pszCollapsedControlText = MakeWString(WStrFactory, SELF.DD.ExpandSeeMoreLabel )  !Collapsed allows 'See details'
       TDCfg:pszExpandedControlText  = MakeWString(WStrFactory, SELF.DD.ExpandSeeLessLabel )  !Expanded  allows 'Hide details'
       SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.ExpandInFooter , TD_Flag_EXPAND_FOOTER_AREA)  !ExpandedInfo is displayed at the bottom of the dialog footer area instead of immediately after the dialog's content. 
       SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.ExpandByDefault, TD_Flag_EXPANDED_BY_DEFAULT) !ExpandedInfo is displayed when the dialog is initially displayed
    END    
    IF SELF.DD.CheckboxLabel THEN 
       TDCfg:pszVerificationText     = MakeWString(WStrFactory, SELF.DD.CheckboxLabel)
       SELF.FlagAdd(dwFLAGS, SELF.DD.CheckboxChecked, TD_Flag_VERIFICATION_FLAG_CHECKED)  !Verification checkbox on dialog is checked when dialog is initially displayed. 
    END 
    
    TDCfg:pszFooter = MakeWString(WStrFactory, SELF.DD.FooterText)
    TDCfg:pszFooterIcon = SELF.DD.IconFooter 

    !--- Buttons and Radios ----------------------------------------
    IF RECORDS(SELF.QBtnQ) THEN     
       QBtn2DlgBtns(WStrFactory, SELF.QBtnQ, Buttons, SELF.DD.Flag.ButtonCmdLinks)
       TDCfg:cButtons =         Buttons.cButtons    !UNSIGNED  !UINT cButtons;                       
       TDCfg:pButtons = ADDRESS(Buttons.pButton )   !UNSIGNED  !TASKDIALOG_BUTTON *pButtons;         
    END
    TDCfg:nDefaultButton = SELF.DD.BtnsDefaultID
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.ButtonCmdLinks, CHOOSE(SELF.DD.Flag.ButtonCmdLinks,TD_Flag_USE_COMMAND_LINKS,TD_Flag_USE_COMMAND_LINKS_NO_ICON))
    
    IF RECORDS(SELF.QRdoQ) THEN
       QBtn2DlgBtns(WStrFactory, SELF.QRdoQ, Radios, 1)
       TDCfg:cRadioButtons =         Radios.cButtons    !UNSIGNED  !UINT cButtons;                       
       TDCfg:pRadioButtons = ADDRESS(Radios.pButton )   !UNSIGNED  !TASKDIALOG_BUTTON *pButtons;         
    END
    IF SELF.DD.RadioDefaultID >= 0 THEN
       TDCfg:nDefaultRadioButton = SELF.DD.RadioDefaultID    
    ELSE ! RadioDefaultID < 0
       SELF.FlagAdd(dwFLAGS, 1,   TD_Flag_NO_DEFAULT_RADIO_BUTTON ) 
    END  
    
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.CancelAllowed,   TD_Flag_ALLOW_DIALOG_CANCELLATION )   
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.Position2Window, TD_Flag_POSITION_RELATIVE_TO_WINDOW )   
    SELF.FlagAdd(dwFLAGS, CHOOSE(~SELF.DD.Flag.Size2ContentOFF) , TD_Flag_SIZE_TO_CONTENT )   
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.Minimizable    , TD_Flag_CAN_BE_MINIMIZED            )   

    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.MarqueeProgress, TD_Flag_SHOW_MARQUEE_PROGRESS_BAR   )   
    SELF.FlagAdd(dwFLAGS, SELF.DD.Progress.Marquee, TD_Flag_SHOW_MARQUEE_PROGRESS_BAR   )   
    SELF.FlagAdd(dwFLAGS, SELF.DD.Progress.Bar_Pos, TD_Flag_SHOW_PROGRESS_BAR   )   

    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.Right2Left     , TD_Flag_RTL_LAYOUT                  )   
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.NoSetForeground, TD_Flag_NO_SET_FOREGROUND           )
    SELF.FlagAdd(dwFLAGS, SELF.DD.Flag.HyperLinks     , TD_Flag_ENABLE_HYPERLINKS           ) 
    IF SELF.DD.Shutdown.Seconds AND  SELF.DD.Shutdown.ButtonID THEN 
       DoCallBack=1    
       SELF.FlagAdd(dwFLAGS, 1 , TD_Flag_CALLBACK_TIMER ) 
       IF TDCfg:pszFooter=0 THEN
          X = SELF.DD.Shutdown.Seconds
          TDCfg:pszFooter = MakeWString(WStrFactory, 'Please answer within ' & |
                            CHOOSE(X<100, x & ' seconds', TimeFmt(X)) & ALL(' ',256))       
       END 
    END 
                
    TDCfg:cxWidth = SELF.DD.Width
    
!    IF SELF.DD.Flag.MarqueeProgress OR SELF.DD.Flag.HyperLinks OR DoCallBack !OR SELF.DD.Progress.Bar_Pos THEN 
    IF DoCallBack OR BAND(dwFLAGS,TD_Flag_SHOW_MARQUEE_PROGRESS_BAR + TD_Flag_SHOW_PROGRESS_BAR + TD_Flag_ENABLE_HYPERLINKS ) THEN 
       BackData.Magic       = ADDRESS(BackData)        !Is Address of this data, seemed like a good safety check
       BackData.TskDlgCls  &= SELF
       BackData.TDCfgData   = ADDRESS(TDConfig)
       TDCfg:pfCallback     = ADDRESS(TaskDialogCallback)
       TDCfg:lpCallbackData = ADDRESS(BackData)
       IF DBdev THEN Self.DB('TDCfg:pfCallback ' & Hex8(TDCfg:pfCallback) &'  Data='& Hex8(TDCfg:lpCallbackData)).
    END
    
    IF False THEN SELF.Test_TaskDialog(TDConfig).  !TODO Allow  try it in TaskDialog to see it works ok

    SELF.VerifyForShow(TDConfig)      !Let developer Override
LOOP_Retry_CYCLE:
    CLEAR(SELF.Result)    
    HR = TaskDialogIndirect(TDConfig, | !const TASKDIALOGCONFIG *pTaskConfig, 
                            SELF.Result.ButtonID,   |   !int *pnButton,      - Button number or ID pressed
                            SELF.Result.RadioID,    |   !int *pnRadioButton  - Radio ID selected
                            SELF.Result.Checked,    )   !BOOL *pfVerificationFlagChecked - Was Checkbox checked
    IF HR < 0 THEN 
        SELF.DevBugReport('CBTaskDlgClass.Show call to TaskDialogIndirect() failed<13,10>HR=' & HR &'  ' & HResultName(HR))
!TODO in DevBugReport window have check boxes to stop warnings. handle ||||
        IF TDCfg:pszMainIcon OR TDCfg:pszFooterIcon THEN    !If there was an Icon try the msg without it
           TDCfg:pszMainIcon=0 ; TDCfg:pszFooterIcon=0
           SELF.FlagRemove(dwFLAGS, 1, BOR(TD_Flag_USE_HICON_MAIN,TD_Flag_USE_HICON_FOOTER) )
           GOTO LOOP_Retry_CYCLE:
        END
        !Defect show
        Message('TOOD Need Fallback TaskDialogIndirect() Failed HR=' & HR &'|  ' & HResultName(HR) &'|LastErr=' & GetLastError(),'CBTaskDlgClass.Show',,'Close|Halt' )
        !TODO make a Window that "crudely" has the features of the TD. Dump all Text into 1 STRING in a TEXT. LIST of RADIOs. LIST of BUTTONs.
    END

    IF SELF.DD.CheckboxLabel THEN SELF.DD.CheckboxChecked=CHOOSE(SELF.Result.Checked).
    
    IF BAND(KEYSTATE(),0300h) THEN SELF.DevBugReport('You pressed Ctrl+Shift+Click').    !Ctrl+Shift+Click shows all the info
    RETURN SELF.Result.ButtonID
!----------------------------------------------
CBTaskDlgClass.VerifyForShow    PROCEDURE(*CBTaskDialogConfigType TDCfg)!,VIRTUAL  !Developer can derive and override config
CfgB4   GROUP(CBTaskDialogConfigType),AUTO
            END   
    CODE
    CfgB4 = TDCfg
    TDCfg.dwCommonButtons   = BAND(TDCfg.dwCommonButtons,TD_ButtonMask)  !Passing unknown raises exception
    IF TDCfg.dwCommonButtons <> CfgB4.dwCommonButtons THEN SELF.DevBugReport('Invalid Common Buttons = ' & CfgB4.dwCommonButtons).
    IF IconIsDefective(0,TDCfg.hMainIcon  ,TDCfg.dwFLAGS) THEN SELF.DevBugReport('Invalid Icon Main = ' & CfgB4.hMainIcon).
    IF IconIsDefective(1,TDCfg.hFooterIcon,TDCfg.dwFLAGS) THEN SELF.DevBugReport('Invalid Icon Footer = ' & CfgB4.hFooterIcon).

    RETURN 
      !TODO make part of class virtual VerifyIcon
IconIsDefective    PROCEDURE(BOOL IsFooter, *LONG Cfg_hIcon, *LONG Cfg_Flags)!,BOOL  True=Bad and Zeros hIcon
    CODE
    IF BAND(Cfg_Flags,CHOOSE(~IsFooter,TD_Flag_USE_HICON_MAIN,TD_Flag_USE_HICON_FOOTER) ) THEN
       RETURN 0 !Icon handle so assume it is ok
    END
!Must consider thse in Cfg_Flags
! TD_Flag_USE_HICON_MAIN                  EQUATE(0002h) !Use icon handle in hMainIcon as the primary icon in the task dialog. If this flag is specified, the pszMainIcon member is ignored.
! TD_Flag_USE_HICON_FOOTER                EQUATE(0004h) !Use icon in the hFooterIcon member as the footer icon in the task dialog. If this flag is specified, the pszFooterIcon member is ignored.
    CASE Cfg_hIcon
    OF 0
    OF 0FFFFh+1-9 TO 0FFFFh+1-1
    OF 32512 TO 32517  !14 
    !OF 0 TO 0FFFFFFh        !test to see crash
    ELSE
        Cfg_hIcon = 0
        RETURN True 
    END    
    RETURN 0

!--------------------------------------------------------------------------------
CBTaskDlgClass.FlagAdd PROCEDURE(*LONG InOutFlags, BOOL pTurnOn, LONG pFlagValue) !If TurnOnFlag then BOR(InOutFlags,pFlagValue)
    CODE
    IF pTurnOn THEN 
       InOutFlags=BOR(InOutFlags,pFlagValue)
       IF DBdev THEN Self.DB('.FlagAdd ' & Hex8(pFlagValue) &' = '& Hex8(InOutFlags)).
    END
    RETURN
CBTaskDlgClass.FlagRemove PROCEDURE(*LONG InOutFlags, BOOL pTurnOff, LONG pFlagValue) !If TurnOffFlag then BAND(InOutFlags,BXOR(-1,pFlagValue)
    CODE
    IF pTurnOff THEN 
       InOutFlags=BAND(InOutFlags,BXOR(-1,pFlagValue))
       IF DBdev THEN Self.DB('.FlagRemove ' & Hex8(pFlagValue) &' = '& Hex8(InOutFlags)).
    END
    RETURN 
!--------------------------------------------------------------------------------
CBTaskDlgClass.Test_TaskDialog   PROCEDURE(*CBTaskDialogConfigType pTskDlgConfig) !Not the Indirect one
nButton     LONG 
TDConfig    GROUP(CBTaskDialogConfigType),PRE(TDCfg),AUTO
            END
HR          SIGNED,AUTO
    CODE
    TDConfig = pTskDlgConfig
    HR = TaskDialog(TDCfg:hwndParent, TDCfg:hInstance, TDCfg:pszWindowTitle, |
                    TDCfg:pszMainInstruction,TDCfg:pszContent,TDCfg:dwCommonButtons,TDCfg:pszMainIcon,nButton)

    CASE Message('TaskDialog() returned HR=' & HR &'   '& HResultName(HR) &'|LastErr=' & GetLastError()&'||nButton=' & nButton , |
                 'CBTaskDlgClass.Test_TaskDialog ',,'Close|Halt' )
    OF 2 ; HALT()
    END
    
    !    1          2              3            4            5        6         7        8
!---------
!    TaskDialog    PROCEDURE( |                                      !HRESULT TaskDialog(
!      1  SIGNED              hwndOwner                 , |               !HWND hwndOwner,
!      2  SIGNED              hInstance                 , |               !HINSTANCE hInstance,   (for Icon Resource)
!      3  PCWSTR              pszWindowTitle            , |               !PCWSTR pszWindowTitle,
!      4  PCWSTR              pszMainInstruction        , |               !PCWSTR pszMainInstruction,
!      5  PCWSTR              pszContent                , |               !PCWSTR pszContent,
!      6  LONG  dwCommonButtons  , |            !TASKDIALOG_COMMON_BUTTON_FLAGS dwCommonButtons,
!      7  PCWSTR              pszIcon                   , |               !PCWSTR pszIcon,
!      8  *SIGNED             pnButton                    |               !int *pnButton
!        ),PASCAL,DLL(_fp_),RAW,LONG!,NAME('TaskDialog_fn')   !This is W Unicode only
!        !Returns  HRESULT of S_OK or E_FAIL etc

!--------------------------------------- 
ButtonID2Equate  PROCEDURE(LONG nButton)!,LONG  !TaskDialog returns Goofy 1,2,3 so convert to Equates passed
    CODE         !           1 IDOK    2 IDCANCEL ,       4 IDRETRY         6 IDYES    7 IDNO    8 IDCLOSE
    RETURN CHOOSE(nButton,TD_BTN:OK,TD_BTN:CANCEL, 00 ,TD_BTN:RETRY, 00 ,TD_BTN:YES,TD_BTN:NO,TD_BTN:CLOSE, 00)
!--------------------------------------- 
ButtonEquate2ID  PROCEDURE(LONG pBtnEquate)!,LONG  !Take ID_Btn: Equate and return button
E LONG,AUTO
    CODE
    CASE pBtnEquate
    OF Td_Btn:OK     ; E=Td_Id_OK 
    OF Td_Btn:YES    ; E=Td_Id_YES   
    OF Td_Btn:NO     ; E=Td_Id_NO    
    OF Td_Btn:RETRY  ; E=Td_Id_RETRY 
    OF Td_Btn:CANCEL ; E=Td_Id_CANCEL
    OF Td_Btn:CLOSE  ; E=Td_Id_CLOSE
    ELSE             ; E=0
    END
    RETURN E
!-----------------------------------
MakeWString     PROCEDURE(CBWStrFactoryClass WFactoryCls, *ANY AnyStr)!,LONG !Convert ANY to WStr if Not Blank
WStrPtr     LONG
    CODE
    IF AnyStr THEN     !Has to be non-blank
       WStrPtr=WFactoryCls.Make1(AnyStr,1)  !1=clip incase ANY &=STRING
       IF DBdev AND WStrPtr THEN ODBWStr(WStrPtr).
    END
    RETURN WStrPtr
MakeWString     PROCEDURE(CBWStrFactoryClass WFactoryCls, STRING Str)!,LONG !Convert STRING to WStr if Not Blank
WStrPtr     LONG
    CODE
    IF Str THEN     !Has to be non-blank
       WStrPtr=WFactoryCls.Make1(Str,1)  !1=clip incase ANY &=STRING
       IF DBdev AND WStrPtr THEN ODBWStr(WStrPtr).
    END
    RETURN WStrPtr    
!-----------------------------------
QBtn2DlgBtns            PROCEDURE(CBWStrFactoryClass WFactoryCls,CBTDBtnQueue BRQ, DlgBtnsType DlgBtns, BYTE pCan1310 )
X      LONG,AUTO
B      LONG,AUTO
    CODE
    CLEAR(DlgBtns)
    LOOP X=1 TO RECORDS(BRQ)
        GET(BRQ,X)
        DlgBtns.cButtons += 1
        DlgBtns.pButton.nButtonID[X]     = BRQ.ID 
        IF ~BRQ.Label THEN BRQ.Label=BRQ.ID.            !No blanks
        LOOP B=1 TO SIZE(BRQ.Label)
             CASE VAL(BRQ.Label[B])
             OF 10  ; IF ~pCan1310 THEN BRQ.Label[B]=''.        !Cannot have 13,10 in Buttons unless Command Links
             OF 13  ; BRQ.Label[B]=''                           !A 13,10 will Double space so remove 13
             OF 124 ; BRQ.Label[B]=CHOOSE(~pCan1310,'','<10>')  !Convert Pipe | to LF, or blank for buttons
             END
        END
        DlgBtns.pButton.pszButtonText[X] = WFactoryCls.Make1(BRQ.Label)
    WHILE X < MaxDlgBtns
    RETURN
!----------------------------------------    
TimeFmt     PROCEDURE(LONG pSecs)!,STRING
Fm  STRING(8),AUTO
X   USHORT,AUTO
    CODE                        !123456
    Fm=FORMAT(pSecs*100+1,@t04) !00:00:00
    LOOP X=1 TO 5
        IF Fm[X]>='1' AND Fm[X]<='9' THEN BREAK. 
        Fm[X]=''
    END
    RETURN CLIP(LEFT(Fm))
!-----------------------------------
CBTaskDlgClass.ShowMessage     PROCEDURE()
!-----------------------------------
!ButtonEqt   LONG
TDBtns      LONG,AUTO
MsgBtns     PSTRING(64)
BtnMap      LONG,DIM(6)
BtnCnt      SHORT
BtnPicked   SHORT
MpTDE       LONG,DIM(6),AUTO
MpNm        PSTRING(8),DIM(6),AUTO
MpID        LONG,DIM(6),AUTO
BX          LONG,AUTO
    CODE
    stop('Make Fallback') ; return 0
!!!    CLEAR(SELF.Result) 
!!!
!!!
!!!!    MESSAGE('CBTaskDlgClass.ShowShowMessage' & |
!!!!            '|Caption=' & SELF.DD.Caption & |
!!!!            '|Instruction=' & SELF.DD.Instruction & |
!!!!            '|-{30}|Content=' & SELF.DD.Content & |
!!!!            '|-{30}|Buttons=' & SELF.DD.BtnsCommon & |
!!!!            '|Icon=' & SELF.DD.Icon )    
!!!    DO LoadTDdataRtn
!!!    BtnPicked=MESSAGE( CHOOSE(~SELF.DD.Instruction,'',CLIP(SELF.DD.Instruction) &'<13,10,13,10>') & |
!!!                            CLIP(SELF.DD.Content), CLIP(SELF.DD.Caption), , MsgBtns )
!!!    IF ~BtnPicked THEN BtnPicked=1. 
!!!    SELF.Result.UsedMessage = 1    
!!!    SELF.Result.ButtonEqt  = MpTDE[ BtnMap[BtnPicked]  ]
!!!    SELF.Result.nButton    = MpID[ BtnMap[BtnPicked]  ]
!!!    RETURN SELF.Result.ButtonEqt
!!!LoadTDdataRtn ROUTINE
!!!  MpTDE[1]=Td_Btn:OK     ; MpNm[1]='OK'     ; MpID[1]=1 ! EQUATE(01)  !return value 1 IDOK      
!!!  MpTDE[2]=Td_Btn:YES    ; MpNm[2]='Yes'    ; MpID[2]=6 ! EQUATE(02)  !return value 6 IDYES
!!!  MpTDE[3]=Td_Btn:NO     ; MpNm[3]='No'     ; MpID[3]=7 ! EQUATE(04)  !return value 7 IDNO
!!!  MpTDE[4]=Td_Btn:RETRY  ; MpNm[4]='Retry'  ; MpID[4]=4 ! EQUATE(16)  !return value 4 IDRETRY
!!!  MpTDE[5]=Td_Btn:CANCEL ; MpNm[5]='Cancel' ; MpID[5]=2 ! EQUATE(08)  !return value 2 IDCANCEL
!!!  MpTDE[6]=Td_Btn:CLOSE  ; MpNm[6]='Close'  ; MpID[6]=8 ! EQUATE(32)  !return value 8 IDCLOSE
!!!
!!!  TDBtns=SELF.DD.BtnsCommon
!!!  IF ~TDBtns THEN TDBtns=Td_Btn:OK.
!!!  LOOP BX=1 TO 6
!!!        IF BAND(TDBtns, MpTDE[BX]) THEN
!!!           MsgBtns=CHOOSE(~MsgBtns,'',MsgBtns & '|') & MpNm[BX]
!!!           BtnCnt += 1
!!!           BtnMap[BtnCnt] =  BX
!!!        END
!!!  END 
!-----------------------------------
!!CBTaskDlgClass.DebugInfoMsg     PROCEDURE()    call Defect Report it has this and much more
!!!-----------------------------------
!!    CODE
!!    MESSAGE('TDLG.| .Caption=' & SELF.DD.Caption & |
!!            '|  .Instruction=' & SELF.DD.Instruction & |
!!            '|-{30}|  .Content=' & SELF.DD.Content & |
!!            '|-{30}|  .BtnsCommon=' & SELF.DD.BtnsCommon & |
!!            '|  .Icon=' & SELF.DD.Icon , 'CBTaskDlgClass.DebugInfoMsg')    
!!    RETURN
!-----------------------------------
CBTaskDlgClass.Proc_4     PROCEDURE()
!-----------------------------------
    CODE
    RETURN
!-----------------------------------
CBTaskDlgClass.Proc_5     PROCEDURE()
!-----------------------------------
    CODE
    RETURN

!============================================

!-------------------------------------------------------------------------------------------------
!===================================== BUTTON / RADIO RELATED ====================================

!----------------------------------------------------------------------
CBTaskDlgClass.Btns_OYNRCL    PROCEDURE(STRING pOYNRCL, <STRING pDefault>) !Set COMMON Btns with string   X=Cancel plus Close Window
X   USHORT,AUTO
N   USHORT,AUTO
B   LONG,AUTO
OYNRCL_Spc EQUATE('OYNRCL ')  !space on end to allow as Delim
    CODE
    SELF.DD.BtnsCommon=0             !should this zero - I think yes since you can specify them all you should
    pOYNRCL=UPPER(pOYNRCL)
    LOOP X=1 TO SIZE(pOYNRCL)
         N=INSTRING(pOYNRCL[X],OYNRCL_Spc)
         IF N THEN 
            B=CHOOSE(N, Td_Btn:OK,Td_Btn:YES,Td_Btn:NO,Td_Btn:RETRY,Td_Btn:CANCEL,Td_Btn:CLOSE,0)
            SELF.DD.BtnsCommon=BOR(SELF.DD.BtnsCommon, B)
         ELSE
            SELF.DevBugReport('.Btns_OYNRCL('& pOYNRCL &') invalid button code "' & pOYNRCL[X] &'".')
         END
    END
    IF ~OMITTED(pDefault) AND pDefault THEN
        N=INSTRING(UPPER(pDefault[1]),OYNRCL_Spc)
        IF N THEN
           SELF.DD.BtnsDefaultID = CHOOSE(N, Td_Id_OK,Td_Id_YES,Td_Id_NO,Td_Id_RETRY,Td_Id_CANCEL,Td_Id_CLOSE,0)
        ELSE
           SELF.DevBugReport('.Btns_OYNRCL('& pOYNRCL &',) invalid Default "' & pDefault &'".')
        END 
    END     
    RETURN 

!-----------------------------------
CBTaskDlgClass.BtnCustomAdd     PROCEDURE(LONG pID, STRING pLabel, BOOL IsDefault)!,BOOL,PROC !Add 1 Button, return False if failed with ID not unique
    CODE
    IF IsDefault THEN SELF.DD.BtnsDefaultID = pID.
    RETURN SELF.QBtn_Add(SELF.QBtnQ, pID, pLabel) 
!-----------------------------------
CBTaskDlgClass.RadioAdd     PROCEDURE(LONG pID, STRING pLabel, BOOL IsDefault)!,BOOL,PROC  !Add 1 Radio, return False if failed with ID not unique
    CODE
    IF IsDefault THEN SELF.DD.RadioDefaultID = pID.    
    RETURN SELF.QBtn_Add(SELF.QRdoQ, pID, pLabel)     
!-----------------------------------
CBTaskDlgClass.BtnCustomKill  PROCEDURE()     !Delete all Buttons
!-----------------------------------
    CODE
    FREE(SELF.QBtnQ)
    RETURN
!-----------------------------------
CBTaskDlgClass.RadiosKill   PROCEDURE()     !Delete all Radios
!-----------------------------------
    CODE
    FREE(SELF.QRdoQ)
    RETURN
!-------------------------------------------------------------------------------------------------
CBTaskDlgClass.QBtn_Add     PROCEDURE(CBTDBtnQueue BRQ, LONG pID, *STRING pLabel)!,BOOL,PROC,PROTECTED !Internal Button Add
AddOk   BOOL(1)
    CODE
    CLEAR(BRQ)
!TODO Check for Zero ID, maybe just +1record    
    BRQ.ID = pID
    GET(BRQ,BRQ.ID)
    IF ~ERRORCODE() THEN   !!The same id is a Problem
        SELF.DevBugReport('Duplicate ' & CHOOSE(ADDRESS(BRQ)=ADDRESS(SELF.QBtnQ),'BUTTON','RADIO') & |
                      ' add of #'  & pID &' "'&    CLIP(pLabel) &'"' & |
                      ' dups #' & BRQ.ID &' "'& CLIP(BRQ.Label) &'"')
        AddOk = False         
    END
    BRQ.Label = pLabel
    ADD(BRQ,BRQ.ID)
    RETURN AddOk
!-------------------------------------------------------------------------------------------------    
CBTaskDlgClass.HRefText PROCEDURE(STRING LinkURL, <STRING PrettyURL>, BYTE TurnOnHyperlinks=1)!,STRING 
    CODE
    IF TurnOnHyperlinks THEN SELF.DD.Flag.Hyperlinks=1.
    RETURN '<<A HREF="' & CLIP(LinkURL) &'">' & |
           CLIP(CHOOSE(~OMITTED(PrettyURL) AND PrettyURL,PrettyURL,LinkURL)) &'<</A>'
!========================================================================================
!-----------------------------------
CBTaskDlgClass.DevBugsAreReported    PROCEDURE(BOOL TurnOn, BOOL GlobalDefault=0)
    CODE
    SELF.DevBugWarn = TurnOn
    IF GlobalDefault THEN GLO:DevBugWarn=TurnOn.
    RETURN 
!-----------------------------------
CBTaskDlgClass.DevBugReport     PROCEDURE(STRING pBugText)
!----------------------------------- 
BugTxt  STRING(LEN(pBugText)+1)
CDTxt   STRING(2000)
LF      EQUATE('<13,10>')
BugWnd WINDOW('Dev Bug Report in TaskDlg2Class'),AT(,,260,130),CENTER,GRAY,SYSTEM,FONT('Consolas',10),RESIZE
        SHEET,AT(1,1,131,15),USE(?SHEET1),NOSHEET
            TAB('Bug Report'),USE(?TAB:DR)
                TEXT,AT(2,20),FULL,USE(BugTxt),FLAT,VSCROLL,READONLY
            END
            TAB('Class Data'),USE(?TAB:CD)
                TEXT,AT(2,20),FULL,USE(CDTxt),FLAT,VSCROLL,READONLY
            END
        END
    END
    
    CODE 
!TODO maybe a Tab with all the Class data showing    
 !   message(pBugText) ; return 
    SELF.DB('*** BUG *** ' & pBugText)
    IF ~SELF.DevBugWarn THEN RETURN.
    BugTxt = pBugText
    DO CDTxtRtn
    OPEN(BugWnd)   !Todo set text 
    
    ACCEPT
    END
    CLOSE(BugWnd)
    RETURN
CDTxtRtn ROUTINE
    CDTxt = 'Task Dlg Class DD.Flags:' &LF&|
    'ButtonCmdLinks =' & SELF.DD.FLAG.ButtonCmdLinks  &LF&|
    'ExpandInFooter =' & SELF.DD.FLAG.ExpandInFooter  &LF&|
    'ExpandByDefault=' & SELF.DD.FLAG.ExpandByDefault &LF&|
    'CancelAllowed  =' & SELF.DD.FLAG.CancelAllowed   &LF&|
    'Position2Window=' & SELF.DD.FLAG.Position2Window &LF&|
    'Size2ContentOFF=' & SELF.DD.FLAG.Size2ContentOFF &LF&|
    'Minimizable    =' & SELF.DD.FLAG.Minimizable     &LF&|
    'MarqueeProgress=' & SELF.DD.FLAG.MarqueeProgress &LF&|
    'Right2Left     =' & SELF.DD.FLAG.Right2Left      &LF&|
    'Hyperlinks     =' & SELF.DD.FLAG.Hyperlinks      &LF&|
    'ElevateBtnID   =' & SELF.DD.FLAG.ElevateBtnID[1] &'  [2]='& SELF.DD.FLAG.ElevateBtnID[2] &LF&|
    'NoSetForeground=' & SELF.DD.FLAG.NoSetForeground &LF&|
    'BtnsCommon     =' & SELF.DD.BtnsCommon      &LF&|
    'BtnsDefaultID  =' & SELF.DD.BtnsDefaultID   &LF&|
    'RadioDefaultID =' & SELF.DD.RadioDefaultID  &LF&|
    'Icon_Main      =' & SELF.DD.Icon_Main       &LF&|
    'IconFooter     =' & SELF.DD.IconFooter      &LF&|
    'Width          =' & SELF.DD.Width           &LF&|
    'hInstance      =' & SELF.DD.hInstance       &LF&|
    'Caption        =' & SELF.DD.Caption         &LF&|
    'Instruction    =' & SELF.DD.Instruction     &LF&|
    'Content        =' & SELF.DD.Content         &LF&|
    'ExpandedText   =' & SELF.DD.ExpandedText    &LF&|
    'SeeMoreLabel   =' & SELF.DD.ExpandSeeMoreLabel    &LF&|
    'SeeLessLabel   =' & SELF.DD.ExpandSeeLessLabel    &LF&|
    'CheckboxLabel  =' & SELF.DD.CheckboxLabel   &LF&|
    'CheckboxChecked=' & SELF.DD.CheckboxChecked &LF&|
    'FooterText     =' & SELF.DD.FooterText      &LF&|
    ''
!------------------------------
CBTaskDlgClass.DB PROCEDURE(STRING Info)
DBC    CSTRING(LEN(Info) + 11 + 3)        
PreFx              EQUATE('[CBTskDlg] ') 
    CODE                   ! 12345678901 
    DBC = PreFx & CLIP(Info) & '<13,10>'
    OutputDebugString(DBC)
    RETURN
!------------------------------

HResultName PROCEDURE(LONG pHR)!,STRING
Nm      STRING(64)
    CODE
    CASE pHR
    OF TD_HR:E_OUTOFMEMORY ; Nm='E_OUTOFMEMORY'
    OF TD_HR:E_INVALIDARG  ; Nm='E_INVALIDARG'
    OF TD_HR:E_FAIL        ; Nm='E_FAIL'
    OF 0                   ; Nm='S_OK'
    OF 1                   ; Nm='S_FALSE'
    OF 2 TO 0FFFFh         ; Nm='S_Unknown'
    ELSE                   ; Nm='Unknown HR' 
    END
    RETURN CLIP(Nm) &' 0x' & Hex8(pHR) &' '& pHR
!------------------------------------------------------------   
Hex8 PROCEDURE(LONG _Lng)!,STRING
LngAdj  LONG,AUTO,STATIC 
L       BYTE,DIM(4),OVER(LngAdj)
Hex     STRING('0123456789ABCDEF'),STATIC
HX      STRING(8),AUTO,STATIC 
  CODE
    LngAdj = BAND(BSHIFT(_Lng, -4),0F0F0F0Fh) + 01010101h
    HX[1]=HEX[L[4]] ; HX[3]=HEX[L[3]] ; HX[5]=HEX[L[2]] ; HX[7]=HEX[L[1]]
    LngAdj=BAND(_Lng,0F0F0F0Fh)  + 01010101h
    HX[2]=HEX[L[4]] ; HX[4]=HEX[L[3]] ; HX[6]=HEX[L[2]] ; HX[8]=HEX[L[1]]
    !HX[9]='h' 
    RETURN HX
!------------------------------------------------------------
IsBadPointer    PROCEDURE(LONG pPtr)!,BOOL  !Santity check pointer will not throw exception
    CODE
    RETURN CHOOSE(pPtr>=0 AND pPtr <= 0FFFFh)

!bool IsBadReadPtr(void* p)
!{MEMORY_BASIC_INFORMATION mbi = {0};
!    if (::VirtualQuery(p, &mbi, sizeof(mbi)))
!    {DWORD mask = (PAGE_READONLY|PAGE_READWRITE|PAGE_WRITECOPY|PAGE_EXECUTE_READ|PAGE_EXECUTE_READWRITE|PAGE_EXECUTE_WRITECOPY);
!        bool b = !(mbi.Protect & mask);
!        // check the page is not a guard page
!        if (mbi.Protect & (PAGE_GUARD|PAGE_NOACCESS)) b = true;
!        return b;}
!    return true;}      
!------------------------------------------------------------
BWStr PROCEDURE(*BSTRING BS, BYTE NullIfBlank=0, BYTE NullIfLenZero=0) !,LONG PWSTR !Returns a PWSTR of the BSTR 
PWStr   LONG,OVER(BS)
    CODE
    IF PWStr=0 THEN !empty, fall thru to return 0
    ELSIF NullIfLenZero AND LEN(BS)=0 THEN RETURN 0
    ELSIF NullIfBlank   AND ~CLIP(BS) THEN RETURN 0
    END
    RETURN PWStr
!------------------------------------------------------------
BStrFromPWStr PROCEDURE(*BSTRING OutBS, LONG InPWStr)!,BOOL !Returns BSTR Set = PWSTR (a copy of it). Returns False if failed
bWorked  BOOL
    CODE 
    IF InPWStr<>OutBS AND ~IsBadPointer(InPWStr) THEN     !Reallocates a previously allocated string to be the size 
       bWorked=SysReAllocString(ADDRESS(OutBS), InPWStr ) !of a second string and copies the second string into the reallocated memory.
    END
    RETURN bWorked

!===========================================================================
TaskDialogCALLBACK  PROCEDURE(SIGNED hWnd, UNSIGNED NotifyNo, UNSIGNED wParam, SIGNED lParam, SIGNED lpRefData )
TDN_DIALOG_CONSTRUCTED     EQUATE(7)  !first message. Dialog is created and about to be displayed.
TDN_CREATED                EQUATE(0)  !!typedef enum _TASKDIALOG_NOTIFICATIONS
TDN_NAVIGATED              EQUATE(1)  !
TDN_BUTTON_CLICKED         EQUATE(2)  !wParam = Button ID
TDN_HYPERLINK_CLICKED      EQUATE(3)  !lParam = (LPCWSTR)pszHREF
TDN_TIMER                  EQUATE(4)  !wParam = Milliseconds since dialog created or timer reset. Requires TD_Flag_CALLBACK_TIMER 
TDN_DESTROYED              EQUATE(5)  !
TDN_RADIO_BUTTON_CLICKED   EQUATE(6)  !wParam = Radio Button ID
TDN_VERIFICATION_CLICKED   EQUATE(8)  !wParam = 1 if checkbox checked, 0 if not, lParam is unused and always 0
TDN_HELP                   EQUATE(9)  !
TDN_EXPANDO_BUTTON_CLICKED EQUATE(10) !wParam = 0 (dialog is now collapsed), wParam != 0 (dialog is now expanded)
!TDM_NAVIGATE_PAGE             EQUATE(400h+101 ) !WM_USER+101,       _TASKDIALOG_MESSAGES
TDM_CLICK_BUTTON              EQUATE(400h+102 ) !WM_USER+102  wParam = Button ID
!TDM_SET_MARQUEE_PROGRESS_BAR  EQUATE(400h+103 ) !WM_USER+103  wParam = 0 (nonMarque) wParam != 0 (Marquee) Chnages Type
TDM_SET_PROGRESS_BAR_STATE    EQUATE(400h+104 ) !WM_USER+104  wParam = new progress state
!TDM_SET_PROGRESS_BAR_RANGE    EQUATE(400h+105 ) !WM_USER+105  lParam = MAKELPARAM(nMinRange, nMaxRange)
TDM_SET_PROGRESS_BAR_POS      EQUATE(400h+106 ) !WM_USER+106  wParam = new position
TDM_SET_PROGRESS_BAR_MARQUEE  EQUATE(400h+107 ) !WM_USER+107  wParam = 0 (stop marquee), wParam != 0 (start marquee), lparam = speed (milliseconds between repaints)
TDM_SET_ELEMENT_TEXT          EQUATE(400h+108 ) !WM_USER+108  wParam = element (TASKDIALOG_ELEMENTS), lParam = new element text (LPCWSTR)
!TDM_CLICK_RADIO_BUTTON        EQUATE(400h+110 ) !WM_USER+110  wParam = Radio Button ID
!TDM_ENABLE_BUTTON             EQUATE(400h+111 ) !WM_USER+111  lParam = 0 (disable), lParam != 0 (enable), wParam = Button ID
!TDM_ENABLE_RADIO_BUTTON       EQUATE(400h+112 ) !WM_USER+112  lParam = 0 (disable), lParam != 0 (enable), wParam = Radio Button ID
!TDM_CLICK_VERIFICATION        EQUATE(400h+113 ) !WM_USER+113  wParam = 0 (unchecked), 1 (checked), lParam = 1 (set key focus)
TDM_UPDATE_ELEMENT_TEXT       EQUATE(400h+114 ) !WM_USER+114  wParam = element (TASKDIALOG_ELEMENTS), lParam = new element text (LPCWSTR)
TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE EQUATE(400h+115 ) !WM_USER+115  wParam = Button ID, lParam = 0 (elevation not required), lParam != 0 (elevation required)
!TDM_UPDATE_ICON               EQUATE(400h+116 ) !WM_USER+116  wParam = icon element (TASKDIALOG_ICON_ELEMENTS), lParam = new icon (hIcon if TDF_USE_HICON_* was set, PCWSTR otherwise)
TDE_CONTENT                       EQUATE(0)     !TASKDIALOG_ELEMENTS
TDE_EXPANDED_INFORMATION          EQUATE(1)     !for TDM_SET_ELEMENT_TEXT
TDE_FOOTER                        EQUATE(2)
TDE_MAIN_INSTRUCTION              EQUATE(3)

X           LONG,AUTO
HResult     LONG 
HR_FALSE    EQUATE(1) !If button click return S_FALSE to tell Task Dialog NOT to close.
HR_OK       EQUATE(0) !Otherwise return S_OK.
BHRef       BSTRING
BTmp        BSTRING
BTmp_WPtr   LONG,OVER(BTmp) 
TimeLeft    LONG,AUTO
CBRefData   &CallBackRefDataTYPE        !Prepared by caller with everythng he knows
CTskDlg     &CBTaskDlgClass             !CBRefData.TskDlgCls
TDConfig    &CBTaskDialogConfigType     !CBRefData.TDCfgData
TDFlags     LONG
    CODE 
   ! STOP('Call back NotifyNo=' & NotifyNo & ' lpRefData=' & lpRefData) 
    IF IsBadPointer(lpRefData) THEN  !This cannot be the pointer so with bad data no point
       RETURN HR_OK
    ELSE
       CBRefData &= (lpRefData)
       IF CBRefData.Magic <> lpRefData THEN 
          IF GLO:DevBugWarn THEN STOP('TaskDialogCALLBACK problem Magic not right<13,10>Magic=' & CBRefData.Magic & '|lpRefData=' & lpRefData ).
          RETURN HR_OK
       END
       CTskDlg  &= CBRefData.TskDlgCls
       TDConfig &= (CBRefData.TDCfgData)
       TDFlags   = TDConfig.dwFlags
    END

    CASE NotifyNo        !https://github.com/jleb/TaskDialog/blob/master/TaskDialog%20Examples.ahk
!no diff OF TDN_DIALOG_CONSTRUCTED  
    OF TDN_CREATED
       IF BAND(TDFlags, TD_Flag_SHOW_MARQUEE_PROGRESS_BAR) THEN  
          SendMessageW(hWnd,TDM_SET_PROGRESS_BAR_MARQUEE, 1, 0)  !wParam=1 (start marquee), lparam = speed (milliseconds between repaints)          
       ELSIF BAND(TDFlags, TD_Flag_SHOW_PROGRESS_BAR) THEN  
          SendMessageW(hWnd,TDM_SET_PROGRESS_BAR_POS, CTskDlg.DD.Progress.Bar_Pos, 0)  !wParam = new position
          IF CTskDlg.DD.Progress.State > 1 THEN   !FYI Paused/Error bars DO not change Bar Pos
              SendMessageW(hWnd,TDM_SET_PROGRESS_BAR_STATE, CTskDlg.DD.Progress.State, 0)  !wParam = new progress state
          END 
       END 
       LOOP X=1 TO MAXIMUM(CTskDlg.dd.flag.ElevateBtnID,1)
          IF CTskDlg.DD.Flag.ElevateBtnID[X] THEN
             SendMessageW(hWnd,TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE, CTskDlg.dd.flag.ElevateBtnID[X], 1) !wParam = Button ID, lParam= 1=(elevation required) 0=(not required)
          END
       END
        
    OF TDN_HYPERLINK_CLICKED !lParam = (LPCWSTR)pszHREF
       CBRefData.TimerReset=1
       !STOP('TDN_HYPERLINK_CLICKED Call back NotifyNo=' & NotifyNo & ' lpRefData=' & lpRefData &'  lParam=' & lParam)
       !POKE(ADDRESS(BHRef),lParam)
       !STOP('BHRef=' & BHRef )  
       !DO See_lParam_Rtn
       !ShellExecuteW(SIGNED hwnd, LONG lpOperation, LONG lpFile, LONG lpParameters, LONG lpDirectory, SIGNED nShowCmd ),SIGNED,PROC,RAW,PASCAL,DLL(1) !Most Unicode LPCW STR
       IF ~IsBadPointer(lParam) THEN
          ODBWStr(lParam)  ! ; IF BStrFromPWStr(lParam, BHRef) THEN Message('URL ' & BHRef) .
          ShellExecuteW(0, 0, lParam)
       END
       
    OF TDN_TIMER !wParam = Milliseconds since dialog created or timer reset. Return S_FALSE(1) to zero tick. Sent every 200ms
       IF CBRefData.TimerReset THEN !User did something so restart his time (or should I just add 1 minute?)
          CBRefData.TimerReset=0 
          CBRefData.TimerLast=0 
          RETURN HR_FALSE           !Returning 1 to the TDN_TIMER notification causes the tickcount to reset
       END
       IF wParam > CBRefData.TimerLast + 2000 THEN  !lets only update every 2 seconds
          CBRefData.TimerLast = wParam
          TimeLeft = CTskDlg.dd.Shutdown.Seconds - Round(wParam / 1000, 1)
          !BTmp = 'Time elapsed: ' & Round(wParam / 1000, 1) & ' seconds ' & wParam
          BTmp = TimeLeft & ' seconds until this closes' !dbg &' w='& wParam & ' l=' & CBRefData.TimerLast
         ! SendMessageW(hWnd,TDM_SET_ELEMENT_TEXT, TDE_FOOTER, BTmp_WPtr )
          SendMessageW(hWnd,TDM_UPDATE_ELEMENT_TEXT, TDE_FOOTER, BTmp_WPtr )
          IF TimeLeft <=0 THEN 
             SendMessageW(hWnd,TDM_CLICK_BUTTON, CTskDlg.DD.Shutdown.ButtonID, 0 )! wParam = Button ID             
          END 
       END

    OF  TDN_BUTTON_CLICKED          !wParam = Button ID
    OROF TDN_HYPERLINK_CLICKED      !lParam = (LPCWSTR)pszHREF
    OROF TDN_RADIO_BUTTON_CLICKED   !wParam = Radio Button ID
    OROF TDN_VERIFICATION_CLICKED   !wParam = 1 if checkbox checked, 0 if not, lParam is unused and always 0
    OROF TDN_EXPANDO_BUTTON_CLICKED !wParam = 0 (dialog is now collapsed), wParam != 0 (dialog is now expanded)
         CBRefData.TimerReset=1

    END !CASE NotifyNo           
  
    RETURN HR_OK
    
    OMIT('**END**')
    ;Check for TDN_TIMER
    If (uNotification = 4) {
        
        If bReset {
            bReset := False
            Return True ;Returning True to the TDN_TIMER notification causes the tickcount to reset
        }
        
        ;Translate time elapsed to UTF-16
        sElapsed := "Time elapsed since last reset: " Round(wParam / 1000, 2) " seconds"
        
        ;Send a TDM_UPDATE_ELEMENT_TEXT message
        SendMessage, 0x400 + 114, 2, &sElapsed,, ahk_id %hwnd%
        
    
          STOP('Call back NotifyNo=' & NotifyNo & ' lpRefData=' & lpRefData &|
                '<13,10>' & TDM_SET_MARQUEE_PROGRESS_BAR &' ? '& 400h + 107) 

btnShow7:
    hModule := DllCall("LoadLibrary", "str", "C:\Windows\system32\shell32.dll")
    hIcon := DllCall("LoadImage", "uint", hModule, "uint", 10, "uint", 1, "uint", 16, "uint", 16, "uint", 0)
    r := TaskDialog(hGui, "TaskDialog() Examples|You can also use custom icons|Here, we're using AHK's own icon from AutoHotkey.exe for the main "
                  . "icon.||But this footer icon uses an icon handle loaded from shell32 in combination with TDF_USE_HICON_FOOTER."
                  , "", 0x4, "\159|" hIcon "|" A_AhkPath)
    DllCall("DestroyIcon", "uint", hIcon), DllCall("FreeLibrary", "uint", hModule)
!------------------------  https://github.com/jleb/TaskDialog/blob/master/TaskDialog%20Examples.ahk
btnShow17:
    TaskDialog(hGui, "TaskDialog() Examples|Normal progress bars require a bit more work than marquee progress bars|This is because you need to "
             . "continually update their position. You first need to use the TDF_SHOW_PROGRESS_BAR flag to display it. Updating its position is "
             . "done through the TDM_SET_PROGRESS_BAR_POS message.`n`nTo ease the updating process, you can also use the TDF_CALLBACK_TIMER flag."
             , "", 0xA00, "", "", "btnShow17Callback")


    !end of OMIT('**END**')

!TODO Convert Pipes in TExt to 13,10. Make it a global option.
!TODO Allow Init default buttons to use Pipes? 
!       Or maybe a new method: BtnsAddPiped('One|Two|Three',Default)    BtnsAddPSV
!       Or  BtnsAddCSV('one','two','three')  but how to do Default 

