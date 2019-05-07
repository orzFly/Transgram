Attribute VB_Name = "Module1"
Private Declare Function GetFileAttributesW Lib "kernel32.dll" (ByVal lpFileName As Long) As Long

Public Function FileExists(ByRef sFileName As String) As Boolean
    Const ERROR_SHARING_VIOLATION = 32&

    Select Case (GetFileAttributesW(StrPtr(sFileName)) And vbDirectory) = 0&
        Case True: FileExists = True
        Case Else: FileExists = Err.LastDllError = ERROR_SHARING_VIOLATION
    End Select
End Function
