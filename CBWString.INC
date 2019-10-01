    OMIT('_EndOfInclude_',_IFDef_CBWStrFactory_)
_IFDef_CBWStrFactory_  EQUATE(1)

!------------------------------------------------------------------------
!CBWStrFactoryClass created by Carl Barnes for CIDC 2019
!A class to Make Unicode Strings and return the Pointer for use in API calls.
!When the class is disposed it then frees all the strings made.
!It is intended to be used in another class that needs to make Wide Strings like Task Dialog

CBWStrQueueType QUEUE,TYPE
WStrPtr             LONG
WStrBytes           LONG     !Actual Bytes defined so 2xWCHR + 2 for 0,0
                END


!----------------- CBWStrFactoryClass -----------------
CBWStrFactoryClass    CLASS,TYPE,MODULE('CBWString.CLW'),LINK('CBWString.CLW',1),DLL(0)   !,_ABCLinkMode_),DLL(_ABCDllMode_)
!
!Properties
!----------
CodePage            LONG            !MultiByteToWideChar Code Page - Default CP_ACP - The system default Windows ANSI code page.
FlagsMBTWC          LONG            !MultiByteToWideChar Flags - Default MB_PRECOMPOSED
Asserts             BOOL            !Turn on to get asserts of problems. Must compile debug

!Methods
!-------
!Init                    PROCEDURE()
!Kill                    PROCEDURE()
Proc_1                  PROCEDURE(),VIRTUAL
!Proc_2                  PROCEDURE(),VIRTUAL
!Proc_3                  PROCEDURE(),VIRTUAL
!Proc_4                  PROCEDURE(),VIRTUAL
!Proc_5                  PROCEDURE(),VIRTUAL

Make1           PROCEDURE(*Cstring sz),LONG                !Make WSTR and return pointer
Make1           PROCEDURE(*String str, BYTE bClip=1),LONG  !Make WSTR and return pointer
Make1           PROCEDURE(STRING sstr, BYTE bClip=0),LONG  !Make WSTR and return pointer
Make1s2c        PROCEDURE(*String str, BYTE bClip=1),LONG !original makes a CSTRING then calls Init(cStr)
Replace1        PROCEDURE(*LONG InOutPtrWideStr, *String InStr, BYTE bClip=1)  !Deletes InOutPtrWideStr from Q then InOutPtrWideStr=Make1()

LenBytes PROCEDURE(<LONG pWStrPtr>),LONG  !Bytes = 2x WChar including <0,0>.  OMIT for last
LenWChar PROCEDURE(<LONG pWStrPtr>),LONG  !WChar including <0,0> = Bytes/2.   OMIT for last

!Methods and Properties not normally used
!----------------------------------------
WStrQ               &CBWStrQueueType,PROTECTED      !Queue of WStr so can Dispose
hProcessHeap        LONG,PROTECTED

Construct           PROCEDURE()
Destruct            PROCEDURE(),VIRTUAL
WStrQ_FreeQ         PROCEDURE(),VIRTUAL,PROTECTED
WStrQ_DeleteQ       PROCEDURE(),VIRTUAL,PROTECTED
WStrQ_AddQ          PROCEDURE(LONG pWStrPtr, LONG pWStrBytes),VIRTUAL,PROTECTED

            END  !CBWStrFactoryClass 
!===================================================================================
!My version of the SVCOM Class. Some improvements. Added STRING w/o * and Clip optional
CBWideStrClass  CLASS,TYPE,MODULE('CBWString.CLW'),LINK('CBWString.CLW',1),DLL(0)
!hProcessHeap        LONG,PROTECTED  !TODO or make a Module Variable like PW AI
CodePage          LONG            !MultiByteToWideChar Code Page - Default CP_ACP - The system default Windows ANSI code page.
FlagsMBTWC        LONG            !MultiByteToWideChar Flags - Default MB_PRECOMPOSED
Asserts           BOOL            !Turn on to get asserts of problems. Must compile debug
Construct         Procedure()
Destruct          Procedure(),virtual
Init              Procedure(*cstring sz, byte bSelfCleaning=true),long,proc !Returns Length made
InitS2C Procedure(*String str, Byte bSelfCleaning=true, Byte bClip=1),long,proc !Clip=2 for ' ' minimum
Init    Procedure(*String str, Byte bSelfCleaning=true, Byte bClip=1),long,proc !Clip=2 for ' ' minimum
Init              Procedure(String str, Byte bSelfCleaning=true, Byte bClip=0),long,proc !Static string
IsInitialised     Procedure(),byte
GetWideStr        Procedure(),long
Len               Procedure(),long
Release           Procedure()
bSelfCleaning     Bool,protected
pWideStr          Long,private      !Pointer to WSTR get using .GetWideStr()
dwBytes           Long,private      !Length of WSTR get using  .Len()

                 END

!Easy to make a UNICODE Wide String from a BSTRING. They were made for that purpose for VB programmers.
!The BSTRING is a Pointer to a WSTRING. It has the <0,0> Null Terminator.
!A blank BSTRING still has a Pointer to a WSTRING that is just a <0,0> terminator.
!To get the WSTRING pointer PEEK(ADDRESS(BSTring),WStrPointer) where WStrPointer is a LONG
!Always use a function (like GetWideStr below) because if you PEEK Wrong you'll crash e.g. PEEK(BStr,) instead of PEEK(Address(BStr) 

!BSTRING Addresses are somewhat immutable i.e. they will change when a new assignment is made to a longer string
!   The old one is destroyed and a new one created with a new address. So ... know that.

CBBStringClass  CLASS,TYPE,MODULE('CBWString.CLW'),LINK('CBWString.CLW',1),DLL(0)
GetWideStr          PROCEDURE(*BSTRING BStr, BYTE NullIfBlank=0, BYTE NullIfLenZero=0),LONG !Returns PWStr of BString
BStrFromPWStr       PROCEDURE(*BSTRING OutBS, LONG InPWStr),BOOL !Returns BSTR Set = PWSTR (a copy of it). Returns False if failed    
                END 
                
!The ADDRESS(BSTRING) is to the POINTER to Wide String<0,0>, POINTER-4 should be the Length Prefix. That's the design.
!
!https://blogs.msdn.microsoft.com/ericlippert/2003/09/12/erics-complete-guide-to-bstr-semantics/ 
!When you call SysAllocString(L"ABCDE") the operating system actually allocates sixteen bytes.
!  The first four bytes are a 32 bit integer representing the number of valid bytes in the string
!  -- initialized to ten in this case.  The next ten bytes belong to the caller and are filled in 
!  with the data passed in to the allocator.  The final two bytes are filled in with zeros. You are 
!  then given a pointer to the data, not to the header.
!
!This immediately explains a few things about BSTRs:
!
!The length can be determined immediately.  SysStringLen does not have to count bytes looking for a 
!    null like wcslen does.  It just looks at the integer preceding the pointer and gives you that value back.
!That's why it is illegal to have a BSTR which points to the middle of another BSTR.  The length 
!    field would not be before the pointer.
!A BSTR can be treated as a PWSZ because there is always a trailing zero put there by the allocator.  
!    You, the caller, do not have to worry about allocating enough space for the trailing zero.
!    If you need a five-character string, ask for five characters.

    _EndOfInclude_