unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XPMan, pcre, PerlRegEx;

type
   TPVariables = record
      variable: String;
      possibleHints: Integer;
      factualHints: Integer;
   end;
   TPVarInFunc = record
      variable: String;
      countHints: Integer;
      global: Boolean;
   end;
   TPVarInFuncArray = array of TPVarInFunc;
   TPVariablesArray = array of TPVariables;
  TForm1 = class(TForm)
    dlgOpen1: TOpenDialog;
    XPManifest1: TXPManifest;
    btn2: TButton;
    mmo2: TMemo;
    btn1: TButton;
    mmo1: TMemo;
    btn3: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure DeleteOtherCommentary(var stringForDelete: String);
    procedure DivFunctionAndWithout(stringForDiv: String; var withoutFunction: String; var allFunction: string);
    procedure SearchGlobalVarsInFunction(stringForSearch: String; var allVaraibles: TPVariablesArray; var allVarInFunc: TPVarInFuncArray);
  end;

var
  Form1: TForm1;
  sFileName, strForMemo: String;
  sFile: Text;

implementation

{$R *.dfm}


procedure TForm1.btn1Click(Sender: TObject);
var
   StrMemo: String;
begin
   if (dlgOpen1.Execute) then
      begin
         mmo1.Clear;
         sFileName := dlgOpen1.FileName;
         AssignFile(sFile, sFileName);
         Reset(sFile);
         while (not EOF(sFile)) do
            begin
               Readln(sFile, strForMemo);
               StrMemo := StrMemo + strForMemo + #13#10;
               //mmo1.Text := mmo1.Text + strForMemo + #13#10;
            end;
         CloseFile(sFile);
         mmo1.Text := mmo1.Text + StrMemo;
      end
   else
      Application.MessageBox('Открытие файла приостановлено','Файл не открыт');
end;

procedure TForm1.btn2Click(Sender: TObject);
var
   i, j, k, m: Integer;
   strFromMemo, strToVariable, strMemo: String;
   RegEx: TPerlRegEx;
   variableFound, commented, commentedTwo, commentedThree: Boolean;
   variablesArray: TPVariablesArray;
   variablesInFunction: TPVarInFuncArray;
   //Variable for search global var's in function's
   globalVar: boolean;
   countFunction: Integer;
   stringForGlobal, stringWithoutFunction, stringWithFunction: String;
   usedGlobalVar: array of Integer;
begin
   k := 0;
   mmo2.Clear;
   strFromMemo := mmo1.Text;

   DeleteOtherCommentary(strFromMemo);
   DivFunctionAndWithout(strFromMemo, stringWithoutFunction, stringWithFunction);

   //mmo1.Text := strFromMemo;

   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '(?<=\$)[a-zA-Z_]\w*';
   RegEx.Subject := stringWithoutFunction;
   RegEx.Compile;
   if (RegEx.Match) then
      begin
         repeat
            variableFound := false;
            SetLength(variablesArray, k + 1);
            for i:=0 to k - 1 do
               if (variablesArray[i].variable = RegEx.MatchedText) then
               begin
                  variableFound := true;
                  inc(variablesArray[i].factualHints);
               end;
            if not(variableFound) then
               begin
                  variablesArray[k].variable := RegEx.MatchedText;
                  inc(variablesArray[k].factualHints);
                  inc(k);
               end;
         until not(RegEx.MatchAgain);
      end;
   countFunction := 0;
   i := 0;
   stringForGlobal := '';
   RegEx.RegEx := '((function)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(.*?)(?=(?:function)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(|$)';
   RegEx.Subject := stringWithFunction;
   RegEx.Compile;
   if (RegEx.Match) then
      begin
         repeat
            Inc(countFunction);
            SearchGlobalVarsInFunction(RegEx.MatchedText, variablesArray, variablesInFunction);
         until not(RegEx.MatchAgain);
      end;
   for i:=0 to k - 1 do
      begin
         if ((variablesArray[i].possibleHints + 1) * countFunction > 0) and (variablesArray[i].factualHints > 0) then
            strMemo := strMemo + variablesArray[i].variable + ' [' + IntToStr(variablesArray[i].factualHints) + ':' + IntToStr((variablesArray[i].possibleHints + 1) * countFunction) + '] ' + ' R = ' + FloatToStrF((variablesArray[i].factualHints / ((variablesArray[i].possibleHints + 1) * countFunction)), ffGeneral, 1, 2) + #13#10
         else
            strMemo := strMemo + variablesArray[i].variable + ' [' + IntToStr(variablesArray[i].factualHints) + ':' + IntToStr((variablesArray[i].possibleHints + 1) * countFunction) + '] ' + ' R = 0' + #13#10;
      end;
   for i:=0 to Length(variablesInFunction) - 1 do
      strMemo := strMemo + 'In Func: ' + variablesInFunction[i].variable + ' [' + IntToStr(variablesInFunction[i].countHints - 1) + '] ' + #13#10;
   mmo2.Text := mmo2.Text + strMemo + 'Количество функций: ' + IntToStr(countFunction) + #13#10;
end;

procedure TForm1.DeleteOtherCommentary(var stringForDelete: String);
var
   RegEx : TPerlRegEx;
   i: Integer;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '\/\/.*';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then
      begin
         repeat
            Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForDelete;
         until not(RegEx.MatchAgain);
      end;

   while (Pos(Chr(13), stringForDelete) > 0) do
      Delete(stringForDelete, Pos(Chr(13), stringForDelete), 2);

   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '\/\*.*?\*\/';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then       
      begin
         repeat
            Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForDelete;
         until not(RegEx.MatchAgain);
      end;
end;

procedure TForm1.btn3Click(Sender: TObject);
var
   i, j, balansed: Integer;
   StringFromMemo, isFunction, allFunction, withoutFunction: string;
   functionIsCopy : Boolean;
begin
   StringFromMemo := mmo1.Text;
   withoutFunction := '';
   mmo2.Clear;
   i := 1;
   j := 0;
   while (i <= Length(StringFromMemo)) do
      begin
         functionIsCopy := false;
         isFunction := '';
         if (StringFromMemo[i] = 'f') and (StringFromMemo[i+1] = 'u') then
            for j:=0 to 7 do
               begin
                  isFunction := isFunction + StringFromMemo[i+j];
               end;
         j := 0;
         if (isFunction = 'function') then
            begin
               balansed := 0;
               while not(functionIsCopy) do
                  begin
                     if (StringFromMemo[i] = '{') then
                        Inc(balansed)
                     else
                        if (StringFromMemo[i] = '}') then
                           begin
                              if (balansed > 0) then
                                 begin
                                    Dec(balansed);
                                    if (balansed = 0) then
                                       begin
                                          functionIsCopy := true;
                                       end;
                                 end;
                           end;
                     if (balansed >= 0) then
                        begin
                           allFunction := allFunction + StringFromMemo[i];
                        end;
                     if (functionIsCopy) then
                        dec(i);
                     inc(i);
                  end;
            end
            else
               withoutFunction := withoutFunction + StringFromMemo[i];
         inc(i);
      end;
   //mmo2.Text := allFunction;
   mmo2.Text := withoutFunction + #13#10 + allFunction;
end;

procedure TForm1.DivFunctionAndWithout(stringForDiv: String;
  var withoutFunction, allFunction: string);
var
   i, j, balansed: Integer;
   isFunction: String;
   functionIsCopy: Boolean;
begin
   withoutFunction := '';
   allFunction := '';
   mmo2.Clear;
   i := 1;
   j := 0;
   while (i <= Length(stringForDiv)) do
      begin
         functionIsCopy := false;
         isFunction := '';
         if (stringForDiv[i] = 'f') and (stringForDiv[i+1] = 'u') then
            for j:=0 to 7 do
               begin
                  isFunction := isFunction + stringForDiv[i+j];
               end;
         j := 0;
         if (isFunction = 'function') then
            begin
               balansed := 0;
               while not(functionIsCopy) do
                  begin
                     if (stringForDiv[i] = '{') then
                        Inc(balansed)
                     else
                        if (stringForDiv[i] = '}') then
                           begin
                              if (balansed > 0) then
                                 begin
                                    Dec(balansed);
                                    if (balansed = 0) then
                                       begin
                                          functionIsCopy := true;
                                       end;
                                 end;
                           end;
                     if (balansed >= 0) then
                        begin
                           allFunction := allFunction + stringForDiv[i];
                        end;
                     if (functionIsCopy) then
                        dec(i);
                     inc(i);
                  end;
            end
            else
               withoutFunction := withoutFunction + stringForDiv[i];
         inc(i);
      end;
end;

procedure TForm1.SearchGlobalVarsInFunction(stringForSearch: String;
  var allVaraibles: TPVariablesArray; var allVarInFunc: TPVarInFuncArray);
var
   i, j, k: Integer;
   RegEx: TPerlRegEx;
   FindVar: String;
   VariableFound: Boolean;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '((?<=global)\s+[\$\w\,\s]*)';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   k := 0;
   i := 1;
   if (RegEx.Match) then
      begin
         repeat
            while (i <= Length(RegEx.MatchedText)) do
               begin
                  VariableFound := False;
                  if (RegEx.MatchedText[i]) = '$' then
                  begin
                     inc(i);
                     while ((RegEx.MatchedText[i] <> ',') and (i <= Length(RegEx.MatchedText))) do
                        begin
                           FindVar := FindVar + RegEx.MatchedText[i];
                           inc(i);
                        end;
                     for j:=0 to k - 1 do
                        if (allVarInFunc[j].variable = FindVar) then
                           begin
                              VariableFound := True;
                              Inc(allVarInFunc[j].countHints);
                           end;
                     if not(VariableFound) then
                        begin
                           SetLength(allVarInFunc, k + 1);
                           allVarInFunc[k].variable := FindVar;
                           allVarInFunc[k].countHints := 1;
                           allVarInFunc[k].global := true;
                           FindVar := '';
                           inc(k);
                        end;
                  end;
                  inc(i);
               end;
         until not(RegEx.MatchAgain);
      end;
   RegEx.RegEx := '(?<=\$)[A-Za-z][A-Za-z_\d]*';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
      begin
         repeat
            for i:=0 to Length(allVarInFunc) - 1 do
               begin
                  if (allVarInFunc[i].variable = RegEx.MatchedText) then
                  begin
                     inc(allVarInFunc[i].countHints);
                     for j:=0 to Length(allVaraibles) - 1 do
                        if (allVaraibles[j].variable = allVarInFunc[i].variable) then
                           inc(allVaraibles[j].factualHints);
                  end;
               end;
         until not(RegEx.MatchAgain);
      end;
end;

end.
