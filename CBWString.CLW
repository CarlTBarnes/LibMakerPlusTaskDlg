                    MEMBER()
!--------------------------
! CBWStrFactoryClass 
!
!--------------------------

!   INCLUDE('EQUATES.CLW')
    INCLUDE('CBWString.INC'),ONCE

CP_ACP                          equate(0)           ! default to ANSI code page

MB_PRECOMPOSED                  equate(00000001h)  ! use precomposed chars
MB_COMPOSITE                    equate(00000002h)  ! use composite chars
MB_USEGLYPHCHARS                equate(00000004h)  ! use glyph chars, not ctrl chars
MB_ERR_INVALID_CHARS            equate(00000008h)  ! error for invalid chars

hProcessHeap LONG         !Does not change so just get once

    MAP
        MODULE('Win32')
    GetProcessHeap(),long,pascal,dll(1)     
    HeapAlloc(long hHeap, long dwFlags, long dwBytes),long,pascal,dll(1) 
    HeapFree(long hHeap, long dwFlags, long lpMem),bool,pascal,proc,dll(1) 
    MultiByteToWideChar(long CodePage, long dwFlags, long lpMultiByteStr, long cbMultiByte, |
                        long lpWideCharStr, long cchWideCharStr),long,pascal,dll(1)
    CBZeroMemory(LONG DestinationPtr, LONG dwLength),PASCAL,NAME('RtlZeroMemory'),DLL(1)
    SysReAllocString(LONG BSTR_pbstr, LONG OLECHAR_psz),SIGNED,RAW,PASCAL,DLL(1)
    GetLastError(),long,pascal,dll(1)                        
        END        
        MODULE('RTL')
LenFastClip PROCEDURE(CONST *STRING Text2Measure),LONG,NAME('Cla$FASTCLIP')  ! LenFastClip=len(clip(  C10
        END
    END

!----------------------------------------
CBWStrFactoryClass.CONSTRUCT        PROCEDURE()
!----------------------------------------
    CODE
    SELF.CodePage   = CP_ACP
    SELF.FlagsMBTWC = MB_PRECOMPOSED
    IF (SELF.WStrQ &= NULL) THEN 
       SELF.WStrQ &= NEW CBWStrQueueType    
    END
    SELF.hProcessHeap = GetProcessHeap()
?   ASSERT(SELF.hProcessHeap)    
    RETURN
!---------------------------------------
CBWStrFactoryClass.DESTRUCT PROCEDURE()
!---------------------------------------
    CODE
    IF NOT (SELF.WStrQ &= NULL)  THEN 
! message('CBWStrFactoryClass.DESTRUCT  frees ' & Records(SELF.WStrQ) )    
       SELF.WStrQ_FreeQ()
    END
    RETURN
        
!!-----------------------------------
!CBWStrFactoryClass.Init     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN
!
!!-----------------------------------
!CBWStrFactoryClass.Kill     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN

!---------------------------------------
CBWStrFactoryClass.WStrQ_FreeQ    PROCEDURE()
!---------------------------------------
  CODE
  LOOP
    GET(SELF.WStrQ, 1)
    IF ERRORCODE() THEN BREAK.
    SELF.WStrQ_DeleteQ()
  END
  FREE(SELF.WStrQ)
  RETURN 
!---------------------------------------
CBWStrFactoryClass.WStrQ_DeleteQ   PROCEDURE()
  CODE !DISPOSE of References in this Q (If are any)
  IF SELF.WStrQ.WStrPtr THEN    
     IF ~HeapFree(SELF.hProcessHeap, 0, SELF.WStrQ.WStrPtr) THEN .  !0=Error
     SELF.WStrQ.WStrPtr = 0
  END 
  DELETE(SELF.WStrQ)
  RETURN
!---------------------------------------
CBWStrFactoryClass.WStrQ_AddQ   PROCEDURE(LONG pWStrPtr, LONG pWStrBytes)
  CODE 
  SELF.WStrQ.WStrPtr   = pWStrPtr
  SELF.WStrQ.WStrBytes = pWStrBytes
  IF pWStrPtr THEN 
     ADD(SELF.WStrQ, SELF.WStrQ.WStrPtr) 
  ELSE 
?     ASSERT(0=SELF.Asserts)
  END
  RETURN
!---------------------------------------
CBWStrFactoryClass.LenBytes PROCEDURE(<LONG pWStrPtr>)  !Bytes = 2x WChar including <0,0>.  OMIT for last
  CODE
  IF OMITTED(pWStrPtr) THEN RETURN(SELF.WStrQ.WStrBytes).  !Omit for Last Make
  IF pWStrPtr=0 THEN RETURN(0).  !Omit for Last Make
  IF SELF.WStrQ.WStrPtr <> pWStrPtr THEN 
     SELF.WStrQ.WStrPtr  = pWStrPtr ; GET(SELF.WStrQ, SELF.WStrQ.WStrPtr) ; IF ERRORCODE() THEN CLEAR(SELF.WStrQ).
  END
  RETURN SELF.WStrQ.WStrBytes
!---------------------------  
CBWStrFactoryClass.LenWChar PROCEDURE(<LONG pWStrPtr>)  !WChar including <0,0> = Bytes/2.   OMIT for last
  CODE 
  IF OMITTED(pWStrPtr) THEN RETURN(SELF.WStrQ.WStrBytes / 2).
  RETURN SELF.LenBytes() / 2
!---------------------------------------


!-----------------------------------
CBWStrFactoryClass.Proc_1     PROCEDURE()
!-----------------------------------
    CODE
    MESSAGE('CBWStrFactoryClass.Proc_1 GetProcessHeap=' & GetProcessHeap() &'|SELF.hProcessHeap=' & SELF.hProcessHeap )
    RETURN
!!-----------------------------------
!CBWStrFactoryClass.Proc_2     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN
!!-----------------------------------
!CBWStrFactoryClass.Proc_3     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN
!!-----------------------------------
!CBWStrFactoryClass.Proc_4     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN
!!-----------------------------------
!CBWStrFactoryClass.Proc_5     PROCEDURE()
!!-----------------------------------
!    CODE
!    RETURN
!---------------------------------------------------------------------
CBWStrFactoryClass.Make1 procedure(*cstring sz)!,LONG !Returns Address
dwWideChrs  long,auto
dwBytes     long,auto
ptrWideStr  long
  code
  !TODO Check for Blank and ?
  !TODO: Web says "Don't use MB_PRECOMPOSED" also that it is ignored
    dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sz), -1, 0, 0)  !-1=CHR(0) terminated 
    IF dwWideChrs THEN 
      dwBytes = dwWideChrs * 2
      ptrWideStr = HeapAlloc(SELF.hProcessHeap, 0, dwBytes)
      IF ptrWideStr THEN 
         dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sz), -1, ptrWideStr, dwWideChrs)
         IF dwWideChrs THEN 
            SELF.WStrQ_AddQ(ptrWideStr,dwBytes)     !We worked so add to queue to dispose
         ELSE
?          IF SELF.Asserts THEN ASSERT(dwWideChrs,'Make1 Cstr MultiByteToWideChar #2 err ' & GetLastError()). 
           IF ~HeapFree(SELF.hProcessHeap, 0, ptrWideStr) THEN 
?              IF SELF.Asserts THEN ASSERT(0,'Make1 Cstr HeapFree err ' & GetLastError()).
           END
           ptrWideStr = 0
        END
      ELSE
?        IF SELF.Asserts THEN ASSERT(ptrWideStr,'Make1 Cstr HeapAlloc err ' & GetLastError()).      
      END
    ELSE
?        IF SELF.Asserts THEN ASSERT(dwWideChrs,'Make1 Cstr MultiByteToWideChar #1 err ' & GetLastError()).          
    END
    IF ~ptrWideStr THEN CLEAR(SELF.WStrQ).
    RETURN ptrWideStr
!---------------------------------------------------------------------
CBWStrFactoryClass.Make1  PROCEDURE(*String str, BYTE bClip=1)!,LONG !Returns Address
sRef   &STRING
sSpace STRING(1) !(' ')
sLen   long,auto
dwBytes long
dwWideChrs  long,auto
ptrWideStr  long
  CODE
  sLen=CHOOSE(~bClip,size(str),LenFastClip(str))
  IF ~sLen THEN 
     IF bClip<>2 THEN RETURN 0.       !Pass 2 for a ' ' string always
     sRef &= sSpace ; sLen=1          !If Length passed is Zero below MB2WC fails so assure at least a space
  ELSE
     sRef &= str
  END

    dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sRef), sLen, 0, 0)  !will NOT include room for <0,0>
    IF dwWideChrs THEN
      dwBytes = dwWideChrs * 2 + 2  !add 2 to allow room to add <0,0> 
      ptrWideStr = HeapAlloc(SELF.hProcessHeap, 0, dwBytes)  !assert(self.pWideStr)
!  stop('1 str=' & str & '<13,10>sLen=' & sLen & ' dwWideChrs=' & dwWideChrs & ' dwBytes=' & dwBytes & '  pWideStr=' & ptrWideStr)                 
      IF ptrWideStr THEN
         dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sRef), sLen, ptrWideStr, dwWideChrs)
         IF dwWideChrs THEN !We WORKED and have a WideStr
            CBZeroMemory(ptrWideStr+dwBytes-2,2)   !must <0,0> after end because converted STRING. Could have used HEAP_ZERO_MEMORY Equate(8)
            SELF.WStrQ_AddQ(ptrWideStr,dwBytes)     !We worked so add to queue to dispose
! stop('2 str=' & str & '<13,10>sLen=' & sLen & ' dwWideChrs=' & dwWideChrs & ' dwBytes=' & dwBytes & '  pWideStr=' & ptrWideStr)           
         ELSE
?          IF SELF.Asserts THEN ASSERT(dwWideChrs,'Make1 Str MultiByteToWideChar #2 err ' & GetLastError()). 
           IF ~HeapFree(SELF.hProcessHeap, 0, ptrWideStr) THEN 
?              IF SELF.Asserts THEN ASSERT(0,'Make1 Str HeapFree err ' & GetLastError()).
           END
           ptrWideStr = 0
         END
      ELSE
?        IF SELF.Asserts THEN ASSERT(ptrWideStr,'Make1 Str HeapAlloc err ' & GetLastError()).       
      END
    ELSE
?        IF SELF.Asserts THEN ASSERT(dwWideChrs,'Make1 Str MultiByteToWideChar #1 err ' & GetLastError()).          
    END
    IF ~ptrWideStr THEN CLEAR(SELF.WStrQ).
    RETURN ptrWideStr
!---------------------------------------------------------------------
CBWStrFactoryClass.Make1s2c  PROCEDURE(*String str, BYTE bClip=1)!,LONG !Returns Address
sz          &cstring
sLen       LONG,AUTO
ptrWideStr  long
  CODE
    !Thought about calling MultiByteToWideChar() here with the STRING but then WStr would not have ending <0,0> w/o adding it
    !probably worth considering since there are so many STRINGs. Try it with my little class first
    sLen=CHOOSE(~bClip,size(str),LenFastClip(str))
    IF sLen=0 THEN RETURN 0.                       !Blank input returns 0 null pointer
    sz &= new cstring(sLen + 1)
?   assert(~sz &= null)
    IF ~sz &= null THEN 
      sz = str[1 : sLen]
      ptrWideStr = SELF.Make1(sz)
      DISPOSE(sz)
    END
    RETURN ptrWideStr    
!---------------------------------------------------------------------
CBWStrFactoryClass.Make1  PROCEDURE(STRING sstr, BYTE bClip=0)
    CODE
    RETURN SELF.Make1(sstr,bClip)
!---------------------------------------------------------------------
CBWStrFactoryClass.Replace1  PROCEDURE(*LONG InOutPtrWideStr, *String InStr, BYTE bClip=1) 
    CODE
    IF InOutPtrWideStr THEN 
       SELF.WStrQ.WStrPtr = InOutPtrWideStr
       GET(SELF.WStrQ,SELF.WStrQ.WStrPtr)
       IF ~ERRORCODE() THEN SELF.WStrQ_DeleteQ().
    END
    InOutPtrWideStr = SELF.Make1(InStr, bClip)
    RETURN
  
    OMIT('**END**')
    

    !end of OMIT('**END**')


!================= Light Weight WideStr ==============================================
!Should I use a BSTRING for Unicode convert? Peek(address(Bstr), GiveAddrWideStr )
CBWideStrClass.Construct procedure
  CODE
  IF ~hProcessHeap THEN hProcessHeap = GetProcessHeap().
  SELF.CodePage = CP_ACP ; SELF.FlagsMBTWC = MB_PRECOMPOSED
  return
CBWideStrClass.Destruct procedure
  code
  if self.bSelfCleaning then self.Release().
  return
!--------------
CBWideStrClass.Init procedure(*cstring sz, byte bSelfCleaning)
dwWideChrs  long,auto
dwbytes     long,auto
  code
    self.bSelfCleaning = bSelfCleaning
    dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sz), -1, 0, 0)  !ACP,PRECOMPOSED
    if dwWideChrs then
      dwBytes = dwWideChrs * 2
      self.pWideStr = HeapAlloc(hProcessHeap, 0, dwBytes)  !assert(self.pWideStr)
      if self.pWideStr then
         dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sz), -1, self.pWideStr, dwWideChrs)
         if dwWideChrs then
            self.dwBytes = dwBytes
         else
            SELF.Release() !HeapFree(GetProcess Heap(), 0, self.pWideStr)  ; self.pWideStr = 0
         end
      end
    end
    return self.dwBytes
!---------------
CBWideStrClass.InitS2C Procedure(*String str, Byte bSelfCleaning=true, Byte bClip=1)
sz      &cstring
sLen    long,auto
dwBytes long
  CODE
  sLen=CHOOSE(~bClip,size(str),LenFastClip(str))
  IF ~sLen THEN 
     IF bClip=2 AND SIZE(str) THEN sLen=1 ELSE RETURN 0.       !Pass 2 for a ' ' string always
  END
!  IF ~sLen AND bClip=2 THEN sLen=1.               !Pass 2 for a ' ' string always
!  IF sLen=0 THEN RETURN 0.                         !Blank input returns 0 null pointer
  sz &= new cstring(sLen + 1)
?   IF SELF.Asserts THEN Assert(~sz &= null).
    IF ~sz &= null THEN
?     IF SELF.Asserts THEN Assert(sLen>0 AND sLen<=size(str)).    
      sz = str[1 : sLen]                    !Carl was--> sz = clip(str) <--chg to save sLen above so avoid clip here
      dwBytes = self.Init(sz, bSelfCleaning)
      DISPOSE(sz)
    END
    RETURN dwBytes
!---------------
CBWideStrClass.Init Procedure(String str, Byte bSelfCleaning=true, Byte bClip=0)
  CODE
  return SELF.init(str,bSelfCleaning,bClip)


!--------------- 
!Make the WSTR direct from the STRING and save the move to CString. That would have cleaned <0>
CBWideStrClass.Init Procedure(*String str, Byte bSelfCleaning=true, Byte bClip=1)
sRef   &STRING
sSpace STRING(1) !(' ')
sLen   long,auto
dwBytes long
dwWideChrs  long,auto

  CODE
  sLen=CHOOSE(~bClip,size(str),LenFastClip(str))
  IF ~sLen THEN 
     IF bClip<>2 THEN RETURN 0.       !Pass 2 for a ' ' string always
     sRef &= sSpace ; sLen=1          !If Length passed is Zero below MB2WC fails so assure at least a space
  ELSE
     sRef &= str
  END

    self.bSelfCleaning = bSelfCleaning
!c    dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sz), -1, 0, 0)  !ACP,PRECOMPOSED
    dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sRef), sLen, 0, 0)  !will NOT include room for <0,0>
    if dwWideChrs then
      dwBytes = dwWideChrs * 2 + 2   !add 2 to allow room to add <0,0> 
      self.pWideStr = HeapAlloc(hProcessHeap, 0, dwBytes)  !assert(self.pWideStr)
!  stop('1 str=' & str & '<13,10>sLen=' & sLen & ' dwWideChrs=' & dwWideChrs & ' dwBytes=' & dwBytes & '  pWideStr=' & SELF.pWideStr)                 
      if self.pWideStr then
         dwWideChrs = MultiByteToWideChar(SELF.CodePage, SELF.FlagsMBTWC, address(sRef), sLen, self.pWideStr, dwWideChrs)
         if dwWideChrs then
            self.dwBytes = dwBytes
            CBZeroMemory(self.pWideStr+dwBytes-2,2)     !must <0,0> after end because converted STRING. Could have used HEAP_ZERO_MEMORY Equate(8)

! stop('2 str=' & str & '<13,10>sLen=' & sLen & ' dwWideChrs=' & dwWideChrs & ' dwBytes=' & dwBytes & '  pWideStr=' & SELF.pWideStr)           
         else
            SELF.Release() !HeapFree(GetProcess Heap(), 0, self.pWideStr)  ; self.pWideStr = 0
         end
      end
    end
    return self.dwBytes

!---------------
CBWideStrClass.IsInitialised procedure
  code
  return choose(self.pWideStr)
CBWideStrClass.GetWideStr procedure
  code
  return self.pWideStr
CBWideStrClass.Len procedure
  code
  return self.dwBytes
CBWideStrClass.Release procedure
  code
  if self.pWideStr then 
     HeapFree(hProcessHeap, 0, self.pWideStr)  !assert(
     self.dwBytes = 0  ; self.pWideStr = 0
  end
  return
!==========================================================================================
CBBStringClass.GetWideStr PROCEDURE(*BSTRING BS, BYTE NullIfBlank=0, BYTE NullIfLenZero=0)!,LONG
PWStr   LONG,OVER(BS)
    CODE
    IF PWStr=0 THEN !empty, fall thru to return 0
    ELSIF NullIfLenZero AND LEN(BS)=0 THEN RETURN 0
    ELSIF NullIfBlank   AND ~CLIP(BS) THEN RETURN 0
    END
    RETURN PWStr
!----------------------------------------------------    
CBBStringClass.BStrFromPWStr PROCEDURE(*BSTRING OutBS, LONG InPWStr)!,BOOL !Returns BSTR Set = PWSTR (a copy of it). Returns False if failed    
bWorked  BOOL
    CODE 
    IF InPWStr<>OutBS AND (InPWStr<0 OR InPWStr>0FFFFh) THEN  !Reallocates a previously allocated string to be the size 
       bWorked=SysReAllocString(ADDRESS(OutBS), InPWStr )     !of a second string and copies the second string into the reallocated memory.
    END
    RETURN bWorked    
