VERSION 5.00
Begin VB.Form MainForm 
   Caption         =   "Telegram 多开伴侣"
   ClientHeight    =   5640
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   12810
   LinkTopic       =   "Form1"
   ScaleHeight     =   5640
   ScaleWidth      =   12810
   StartUpPosition =   1  '所有者中心
   Begin VB.CheckBox chkLogo 
      Caption         =   "logo_256.png"
      Height          =   255
      Left            =   2880
      TabIndex        =   5
      Top             =   360
      Value           =   1  'Checked
      Width           =   2415
   End
   Begin VB.CheckBox chkLogoNoMargin 
      Caption         =   "logo_256_no_margin.png"
      Height          =   255
      Left            =   2880
      TabIndex        =   4
      Top             =   120
      Value           =   1  'Checked
      Width           =   2415
   End
   Begin VB.TextBox txtProductName 
      Height          =   300
      Left            =   1440
      MaxLength       =   8
      TabIndex        =   2
      Text            =   "Telebox"
      Top             =   315
      Width           =   1335
   End
   Begin VB.TextBox Text1 
      Height          =   4815
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   1
      Top             =   720
      Width           =   12615
   End
   Begin VB.CommandButton Command1 
      Caption         =   "搞"
      Default         =   -1  'True
      Height          =   495
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   1215
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "产品名："
      Height          =   180
      Left            =   1440
      TabIndex        =   3
      Top             =   120
      Width           =   720
   End
End
Attribute VB_Name = "MainForm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Command1_Click()
    Dim fileNum As Integer
    Dim bytes() As Byte

    fileNum = FreeFile

    Dim backupFile As String
    Dim exeFile As String
    Dim inputFile As String
    Dim outputFile As String
    Dim productName As String
    Dim logo As Boolean
    Dim logoNoMargin As Boolean
    
    productName = Me.txtProductName.Text
    If Len(productName) = 0 Or Len(productName) > Len("Telegram") Then
        MsgBox "Product Name too long or too short", vbExclamation
        Exit Sub
    End If
    logo = Me.chkLogo.value = vbChecked
    logoNoMargin = Me.chkLogoNoMargin.value = vbChecked
    
    exeFile = GetPath(CurDir, "Telegram.exe")
    backupFile = GetPath(CurDir, "Telegram.bak")
    If Not FileExists(exeFile) Then
        MsgBox "Place this program alongside Telegram.exe!", vbExclamation
        Exit Sub
    End If
    
    If FileExists(backupFile) Then
        inputFile = backupFile
        outputFile = exeFile
    Else
        inputFile = exeFile
        outputFile = exeFile
    End If
    
    Log "Start" & vbCrLf & _
        "inputFile: " & inputFile & vbCrLf & _
        "outputFile: " & outputFile & vbCrLf & _
        "productName: " & productName & vbCrLf & _
        "logo: " & logo & vbCrLf & _
        "logoNoMargin: " & logoNoMargin

    Open inputFile For Binary As #fileNum
    ReDim bytes(LOF(fileNum) - 1)
    Get #fileNum, , bytes
    Close #fileNum
    Log "Read: " & inputFile
    
    If inputFile <> backupFile Then
        Open backupFile For Binary As fileNum
        Put #fileNum, , bytes
        Close fileNum
        Log "Written: " & backupFile
    End If
    
    ReplaceInArray bytes, "Telegram", productName
    ReplaceInArray bytes, "Telegram Desktop", productName & " Desktop"
    ReplaceInArray bytes, "Telegram (%1)", productName & " (%1)"

    If logo Then ReplaceInArray bytes, ":/gui/art/logo_256.png", "./logo_256.png"
    If logoNoMargin Then ReplaceInArray bytes, ":/gui/art/logo_256_no_margin.png", "./logo_256_no_margin.png"
    
    Open outputFile For Binary As fileNum
    Put #fileNum, , bytes
    Close fileNum
    Log "Written: " & outputFile
End Sub

Private Function GetPath(Optional base As String = "", Optional append As String = "")
    If Len(base) = 0 Then base = App.Path
    GetPath = IIf(Right(base, 1) = "\", base, base & "\") & append
End Function

Private Sub ReplaceInArray(ByRef bytes() As Byte, find As String, replace As String)
    If Len(replace) > Len(find) Then
        Err.Raise vbObjectError, , "String too long"
    End If
    
    Dim i As Long

    Dim findPattern() As Byte
    ReDim findPattern(4 + Len(find) * 2 - 1)
    FillByteArray findPattern
    For i = 1 To Len(find)
        findPattern(i * 2) = Asc(Mid(find, i, 1))
    Next

    Dim replacePattern() As Byte
    ReDim replacePattern(4 + Len(find) * 2 - 1)
    FillByteArray replacePattern
    For i = 1 To Len(replace)
        replacePattern(i * 2) = Asc(Mid(replace, i, 1))
    Next

    Log "Targeted" & vbCrLf & _
        "f: " & find & vbCrLf & _
        "F: " & ByteArrayToHex(findPattern) & vbCrLf & _
        "r: " & replace & vbCrLf & _
        "R: " & ByteArrayToHex(replacePattern)
    
    Dim Pos As Long
    Pos = 1
    Do While True
        Pos = InStrB(Pos, bytes, findPattern, vbBinaryCompare)
        If Pos = 0 Then Exit Do
        
        Log "Found @" & HexOffset(Pos - 1)
        'ByteArrayToHex(bytes, Pos - 1, Pos - 1 + (UBound(findPattern) + 1) - 1)
        
        Dim pStart As Long
        pStart = Pos - 1
        For i = 0 To UBound(findPattern)
            If bytes(pStart + i) <> findPattern(i) Then Err.Raise vbObjectError, , "Assert failed (Source mismatch)"
            bytes(pStart + i) = replacePattern(i)
        Next i

        Pos = Pos + 1
    Loop
End Sub

Private Function HexOffset(o As Long)
    HexOffset = Right("00000000" & Hex(o), 8)
End Function

Private Sub FillByteArray(bytes() As Byte, Optional value As Byte = 0)
    Dim i As Integer
    For i = LBound(bytes) To UBound(bytes)
        bytes(i) = value
    Next
End Sub

Private Function ByteArrayToHex(bytes() As Byte, Optional LRange = Null, Optional URange = Null)
    If IsNull(LRange) Then LRange = LBound(bytes)
    If IsNull(URange) Then URange = UBound(bytes)
    If URange < 0 Then URange = UBound(bytes) + URange

    Dim s As String, i As Long
    s = ""
    For i = LRange To URange
        s = s & Right("000" & Hex(bytes(i)), 2) & " "
    Next
    ByteArrayToHex = Left(s, Len(s) - 1)
End Function

Private Sub Log(s As String)
    Me.Text1.SelStart = Len(Me.Text1.Text)
    Me.Text1.SelText = Date & " " & Time & " " & s & vbCrLf & vbCrLf
    Me.Text1.SelStart = Len(Me.Text1.Text)
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    Me.Text1.Width = Me.ScaleWidth - Me.Text1.Left * 2
    Me.Text1.Height = Me.ScaleHeight - Me.Text1.Top - Me.Text1.Left
End Sub
