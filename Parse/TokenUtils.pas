unit TokenUtils;

{ AFS 2 Jan
  procedureal code that works on the parse tree
  not put on the class as it's most fairly specific stuff
    (but has been put here because 2 or more processes use it )
  and needs to know both classes - TParseTreeNode and TSoruceTOken
  }

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is TokenUtils, released May 2003.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2000 Anthony Steele.
All Rights Reserved. 
Contributor(s): Anthony Steele. 

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.
------------------------------------------------------------------------------*)
{*)}

interface

uses ParseTreeNode, SourceToken;

{ make a new return token }
function NewReturn: TSourceToken;
function NewSpace(const piLength: integer): TSourceToken;

procedure InsertTokenAfter(const pt, ptNew: TSourceToken);
procedure InsertTokenBefore(const pt, ptNew: TSourceToken);

function InsertReturnAfter(const pt: TSourceToken): TSourceToken;
function InsertSpacesBefore(const pt: TSourceToken;
  const piSpaces: integer): TSourceToken;

{ effectively remove the token by making it empty }
procedure BlankToken(const pt: TSourceToken);

{ return the name of the procedure around any parse tree node or source token
  empty string if there is none }
function GetProcedureName(const pcNode: TParseTreeNode; const pbFullName: boolean;
  const pbTopmost: boolean): string;


{ depending on context, one of Procedure, function, constructor, destructor }
function GetBlockType(const pcNode: TParseTreeNode): string;


function ExtractNameFromFunctionHeading(const pcNode: TParseTreeNode;
  const pbFullName: boolean): string;

function IsClassFunction(const pt: TSourceToken): boolean;

function RHSExprEquals(const pt: TSourceToken): boolean;

function RHSTypeEquals(const pt: TSourceToken): boolean;

function IsClassDirective(const pt: TSourceToken): boolean;

function RoundBracketLevel(const pt: TSourceToken): integer;
function SquareBracketLevel(const pt: TSourceToken): integer;
function AllBracketLevel(const pt: TSourceToken): integer;
function BlockLevel(const pt: TSourceToken): integer;
function CaseLevel(const pt: TSourceToken): integer;

function InRoundBrackets(const pt: TSourceToken): boolean;

function SemicolonNext(const pt: TSourceToken): boolean;

{ true if the token is in code, ie in procedure/fn body,
  init section, finalization section, etc

  False if it is vars, consts, types etc
  or in asm }
function InStatements(const pt: TSourceToken): boolean;
function InProcedureDeclarations(const pt: TsourceToken): boolean;
function InDeclarations(const pt: TsourceToken): boolean;

function IsCaseColon(const pt: TSourceToken): boolean;
function IsLabelColon(const pt: TSourceToken): boolean;

function IsFirstSolidTokenOnLine(const pt: TSourceToken): boolean;

function IsUnaryOperator(const pt: TSourceToken): boolean;

function InFormalParams(const pt: TSourceToken): boolean;

function IsActualParamOpenBracket(const pt: TSourceToken): boolean;
function IsFormalParamOpenBracket(const pt: TSourceToken): boolean;

function IsLineBreaker(const pcToken: TSourceToken): boolean;
function IsMultiLineComment(const pcToken: TSourceToken): boolean;
function IsSingleLineComment(const pcToken: TSourceToken): boolean;

function IsBlankLineEnd(const pcToken: TSourceToken): boolean;

function VarIdentCount(const pcNode: TParseTreeNode): integer;
function IdentListNameCount(const pcNode: TParseTreeNode): integer;

function ProcedureHasBody(const pt: TParseTreeNode): boolean;

function IsDfmIncludeDirective(const pt: TSourceToken): boolean;
function IsGenericResIncludeDirective(const pt: TSourceToken): boolean;

function FirstSolidChild(const pt: TParseTreeNode): TParseTreeNode;

function InFilesUses(const pt: TParseTreeNode): boolean;


function Root(const pt: TParseTreeNode): TParseTreeNode;

function UnitName(const pt: TParseTreeNode): string;

{ use to build a parse tree}
function IsIdentifierToken(const pt: TSourceToken): boolean;
{ use on a built parse tree }
function IsIdentifier(const pt: TSourceToken): boolean;

function IsHintDirective(const pt: TSourceToken): boolean;

function HashLiteral(const pt: TSourceToken): boolean;


implementation

uses
  SysUtils,
  JclStrings,
  ParseTreeNodeType, Tokens, Nesting;


function NewReturn: TSourceToken;
begin
  Result := TSourceToken.Create;
  Result.TokenType := ttReturn;
  Result.SourceCode := AnsiLineBreak;
end;

function NewSpace(const piLength: integer): TSourceToken;
begin
  Assert(piLength > 0, 'Bad space length of' + IntToStr(piLength));

  Result := TSourceToken.Create;
  Result.TokenType := ttWhiteSpace;
  Result.SourceCode := StrRepeat(AnsiSpace, piLength);
end;

procedure InsertTokenAfter(const pt, ptNew: TSourceToken);
begin
  Assert(pt <> nil);
  Assert(pt.Parent <> nil);
  Assert(ptNew <> nil);

  pt.Parent.InsertChild(pt.IndexOfSelf + 1, ptNew);
end;

procedure InsertTokenBefore(const pt, ptNew: TSourceToken);
begin
  Assert(pt <> nil);
  Assert(pt.Parent <> nil);
  Assert(ptNew <> nil);

  pt.Parent.InsertChild(pt.IndexOfSelf, ptNew);
end;

function InsertReturnAfter(const pt: TSourceToken): TSourceToken;
begin
  Assert(pt <> nil);
  Assert(pt.Parent <> nil);

  Result := NewReturn;

  InsertTokenAfter(pt, Result);
end;

function InsertSpacesBefore(const pt: TSourceToken;
  const piSpaces: integer): TSourceToken;
begin
  Assert(pt <> nil);
  Assert(pt.Parent <> nil);

  Result := NewSpace(piSpaces);
  pt.Parent.InsertChild(pt.IndexOfSelf, Result);
end;

procedure BlankToken(const pt: TSourceToken);
begin
  pt.TokenType  := ttWhiteSpace;
  pt.SourceCode := '';
end;

{ given a function header parse tree node, extract the fn name underneath it }
function ExtractNameFromFunctionHeading(const pcNode: TParseTreeNode;
  const pbFullName: boolean): string;
var
  liLoop:      integer;
  lcChildNode: TParseTreeNode;
  lcSourceToken: TSourceToken;
  lcNameToken: TSourceToken;
  lcPriorToken1, lcPriorToken2: TSourceToken;
begin
  lcNameToken := nil;

  { function heading is of one of these forms
      function foo(param: integer): integer;
      function foo: integer;
      function TBar.foo(param: integer): integer;
      function TBar.foo: integer;

    within the fn heading, the name will be last identifier before nFormalParams or ':'

  }
  for liLoop := 0 to pcNode.ChildNodeCount - 1 do
  begin
    lcChildNode := pcNode.ChildNodes[liLoop];

    if lcChildNode.NodeType = nFormalParams then
      break;

    if lcChildNode is TSourceToken then
    begin
      lcSourceToken := TSourceToken(lcChildNode);

      { keep the name of the last identifier }
      if lcSourceToken.TokenType in IdentiferTokens then
        lcNameToken := lcSourceToken
      else if lcSourceToken.TokenType = ttColon then
        break;
    end
    else if (lcChildNode.NodeType = nIdentifier) then
    begin
      lcNameToken := TSourceToken(lcChildNode.FirstLeaf);
    end;
  end;

  if lcNameToken = nil then
    Result := ''
  else if pbFullName then
  begin
    Result := lcNameToken.SourceCode;

    // is it a qualified name
    lcPriorToken1 := lcNameToken.PriorSolidToken;
    if (lcPriorToken1 <> nil) and (lcPriorToken1.TokenType = ttDot) then
    begin
      lcPriorToken2 := lcPriorToken1.PriorSolidToken;
      if (lcPriorToken2 <> nil) and (lcPriorToken2.TokenType in IdentiferTokens) then
      begin
        Result := lcPriorToken2.SourceCode + lcPriorToken1.SourceCode +
          lcNameToken.SourceCode;
      end;
    end;
  end
  else
  begin
    // just the proc name, no prefix
    Result := lcNameToken.SourceCode;
  end;
end;

function GetProcedureName(const pcNode: TParseTreeNode; const pbFullName: boolean;
  const pbTopmost: boolean): string;
var
  lcFunction, lcTemp, lcHeading: TParseTreeNode;
begin
  Assert(pcNode <> nil);

  lcFunction := pcNode.GetParentNode(ProcedureNodes);

  if lcFunction = nil then
  begin
    // not in a function, procedure or method
    Result := '';
    exit;
  end;

  if pbTopmost then
  begin
    { find the top level function }
    lcTemp := lcFunction.GetParentNode(ProcedureNodes);
    while lcTemp <> nil do
    begin
      lcFunction := lcTemp;
      lcTemp     := lcFunction.GetParentNode(ProcedureNodes);
    end;
  end;

  lcHeading := lCFunction.GetImmediateChild(ProcedureHeadings);

  Result := ExtractNameFromFunctionHeading(lcHeading, pbFullName)
end;

function GetBlockType(const pcNode: TParseTreeNode): string;
var
  lcFunction: TParseTreeNode;
begin
  lcFunction := pcNode.GetParentNode(ProcedureNodes + [nInitSection]);

  if lcFunction = nil then
  begin
    Result := '';
    exit;
  end;

  case lcFunction.NodeType of
    nProcedureDecl:
      Result := 'procedure';
    nFunctionDecl:
      Result := 'function';
    nConstructorDecl:
      Result := 'constructor';
    nDestructorDecl:
      Result := 'destructor';
    nInitSection:
      Result := 'initialization section';
    else
      Result := '';
  end;
end;

function IsClassFunction(const pt: TSourceToken): boolean;
begin
  Result := pt.IsOnRightOf(ProcedureHeadings, [ttClass]);
end;

function RHSExprEquals(const pt: TSourceToken): boolean;
begin
  Result := pt.IsOnRightOf(nExpression, ttEquals);
end;

function RHSTypeEquals(const pt: TSourceToken): boolean;
begin
  Result := pt.IsOnRightOf(nType, ttEquals);
end;

function IsClassDirective(const pt: TSourceToken): boolean;
begin
  { property Public: Boolean;
    function Protected: Boolean
    are both legal so have to check that we're not in a property or function def. }

  Result := (pt.TokenType in ClassDirectives) and
    pt.HasParentNode(nClassVisibility, 1) and
    ( not (pt.HasParentNode(ProcedureNodes + [nProperty])));
end;

function RoundBracketLevel(const pt: TSourceToken): integer;
begin
  if pt = nil then
    Result := 0
  else
    Result := pt.Nestings.GetLevel(nlRoundBracket);
end;

function InRoundBrackets(const pt: TSourceToken): boolean;
begin
  if pt = nil then
    Result := False
  else
    Result := (pt.Nestings.GetLevel(nlRoundBracket) > 0);
end;


function SquareBracketLevel(const pt: TSourceToken): integer;
begin
  if pt = nil then
    Result := 0
  else
    Result := pt.Nestings.GetLevel(nlSquareBracket);
end;

function AllBracketLevel(const pt: TSourceToken): integer;
begin
  Result := RoundBracketLevel(pt) + SquareBracketLevel(pt);
end;

function BlockLevel(const pt: TSourceToken): integer;
begin
  if pt = nil then
    Result := 0
  else
    Result := pt.Nestings.GetLevel(nlBlock);
end;

function CaseLevel(const pt: TSourceToken): integer;
begin
  if pt = nil then
    Result := 0
  else
    Result := pt.Nestings.GetLevel(nlCaseSelector);
end;


function SemicolonNext(const pt: TSourceToken): boolean;
var
  lcNext: TSourceToken;
begin
  Result := False;

  if pt <> nil then
  begin
    lcNext := pt.NextSolidToken;
    if lcNext <> nil then
      Result := (lcNext.TokenType = ttSemiColon);
  end;
end;

function InStatements(const pt: TSourceToken): boolean;
begin
  Result := pt.HasParentNode(nStatementList) or pt.HasParentNode(nBlock);
  Result := Result and ( not pt.HasParentNode(nAsm));
end;

function InProcedureDeclarations(const pt: TsourceToken): boolean;
begin
  Result := (pt.HasParentNode(ProcedureNodes) and
    (pt.HasParentNode(InProcedureDeclSections)))
end;

function InDeclarations(const pt: TsourceToken): boolean;
begin
  Result := ( not InStatements(pt)) and ( not pt.HasParentNode(nAsm)) and
    pt.HasParentNode(nDeclSection);
end;

function IsLabelColon(const pt: TSourceToken): boolean;
begin
  Result := (pt.TokenType = ttColon) and pt.HasParentNode(nStatementLabel, 1);
end;


function IsCaseColon(const pt: TSourceToken): boolean;
begin
  Result := (pt.TokenType = ttColon) and pt.HasParentNode(nCaseLabels, 1);
end;

function IsFirstSolidTokenOnLine(const pt: TSourceToken): boolean;
begin
  Result := pt.IsSolid and (pt.SolidTokenOnLineIndex = 0);
end;

function IsUnaryOperator(const pt: TSourceToken): boolean;
begin
  Result := (pt <> nil) and (pt.TokenType in PossiblyUnarySymbolOperators);
  if not Result then
    exit;

  { now must find if there is another token before it,
    ie true for the minus sign in '-2' but false for '2-2' }

  Result := pt.HasParentNode(nUnaryOp, 1);
end;

function InFormalParams(const pt: TSourceToken): boolean;
begin
  Result := (RoundBracketLevel(pt) = 1) and pt.HasParentNode(nFormalParams);
end;

function IsActualParamOpenBracket(const pt: TSourceToken): boolean;
begin
  Result := (pt.TokenType = ttOpenBracket) and (pt.HasParentNode(nActualParams, 1));
end;

function IsFormalParamOpenBracket(const pt: TSourceToken): boolean;
begin
  Result := (pt.TokenType = ttOpenBracket) and (pt.HasParentNode(nFormalParams, 1));
end;


function IsMultiLineComment(const pcToken: TSourceToken): boolean;
begin
  Result := False;

  if pcToken.TokenType <> ttComment then
    exit;

  // double-slash coments are never multiline
  if (pcToken.CommentStyle = eDoubleSlash) then
    exit;

  // otherwise, if it contains a return it's not single line 
  if (Pos(AnsiLineBreak, pcToken.SourceCode) <= 0) then
    exit;

  Result := True;
end;

function IsSingleLineComment(const pcToken: TSourceToken): boolean;
begin
  if pcToken.TokenType <> ttComment then
    Result := False
  else
    Result := not IsMultiLineComment(pcToken);
end;

function IsBlankLineEnd(const pcToken: TSourceToken): boolean;
var
  lcPrev: TSourceToken;
begin
  Result := False;
  if (pcToken <> nil) and (pcToken.TokenType = ttReturn) then
  begin
    lcPrev := pcToken.PriorToken;
    Result := (lcPrev <> nil) and (lcPrev.TokenType = ttReturn);
  end;
end;

function IsLineBreaker(const pcToken: TSourceToken): boolean;
begin
  Result := (pcToken.TokenType = ttReturn) or IsMultiLineComment(pcToken);
end;

{ count the number of identifiers in the var decl
  e.g. "var i,j,k,l: integer" has 4 vars
}
function VarIdentCount(const pcNode: TParseTreeNode): integer;
var
  lcIdents: TParseTreeNode;
begin
  Result := 0;
  if pcNode.NodeType <> nVarDecl then
    exit;

  { the ident list is an immediate child of the var node }
  lcIdents := pcNode.GetImmediateChild(nIdentList);
  Assert(lcIdents <> nil);

  Result := IdentListNameCount(lcIdents);
end;

function IdentListNameCount(const pcNode: TParseTreeNode): integer;
var
  liLoop:     integer;
  lcLeafItem: TParseTreeNode;
begin
  Result := 0;
  if pcNode.NodeType <> nIdentList then
    exit;

  {and under it we find words (names), commas and assorted white space
   count the names }
  for liLoop := 0 to pcNode.ChildNodeCount - 1 do
  begin
    lcLeafItem := pcNode.ChildNodes[liLoop];
    if (lcLeafItem is TSourceToken) and
      (TSourceToken(lcLeafItem).TokenType = ttWord) then
      Inc(Result);
  end;
end;

function ProcedureHasBody(const pt: TParseTreeNode): boolean;
var
  lcProcedureNode: TParseTreeNode;
begin
  Result := False;
  if pt = nil then
    exit;

  lcProcedureNode := pt.GetParentNode(ProcedureNodes);
  if lcProcedureNode = nil then
    exit;

  Result := lcProcedureNode.HasChildNode(nBlock, 1);
end;

function IsDfmIncludeDirective(const pt: TSourceToken): boolean;
begin
  // form dfm comment
  Result := (pt.TokenType = ttComment) and AnsiSameText(pt.SourceCode, '{$R *.dfm}') and
    pt.HasParentNode(nImplementationSection, 4);
end;

function IsGenericResIncludeDirective(const pt: TSourceToken): boolean;
begin
  // form dfm comment
  Result := (pt.TokenType = ttComment) and AnsiSameText(pt.SourceCode, '{$R *.res}');
end;


{ get the first child node that is not a space leaf}
function FirstSolidChild(const pt: TParseTreeNode): TParseTreeNode;
var
  liLoop:  integer;
  lcChild: TParseTreeNode;
begin
  Result := nil;
  for liLoop := 0 to pt.ChildNodeCount - 1 do
  begin
    lcChild := pt.ChildNodes[liLoop];

    if (lcChild is TSourceToken) then
    begin
      if TSourceToken(lcChild).IsSolid then
      begin
        Result := lcChild;
        break;
      end;
    end
    else
    begin
      Result := lcChild;
      break;
    end;
  end;
end;

{ these uses clauses can specify file names for the units }
function InFilesUses(const pt: TParseTreeNode): boolean;
begin
  Assert(pt <> nil);
  Result := pt.HasParentNode(nUses) and
    pt.HasParentNode([nProgram, nPackage, nLibrary]);
end;

function Root(const pt: TParseTreeNode): TParseTreeNode;
begin
  Result := pt;
  while (Result <> nil) and (Result.Parent <> nil) do
    Result := Result.Parent;
end;

function UnitName(const pt: TParseTreeNode): string;
var
  lcRoot: TParseTreeNode;
  lcUnitHeader: TParseTreeNode;
  lcName: TSourceToken;
begin
  Result := '';

  { go to the top }
  lcRoot := Root(pt);
  if lcRoot = nil then
    exit;

  { find the unit header }
  lcUnitHeader := lcRoot.GetImmediateChild(nUnitHeader);
  if lcUnitHeader = nil then
    exit;

  { tokens therein are of the form 'program foo' or 'unit bar' }
  lcName := TSourceToken(lcUnitHeader.FirstLeaf);
  lcName := lcName.NextSolidToken;
  if lcName = nil then
    exit;

  if (lcName.TokenType = ttWord) then
    Result := lcName.SourceCode;
end;

function IsIdentifierToken(const pt: TSourceToken): boolean;
const
  FUDGE_NAMES = [ttOut];
begin
  Result := (pt <> nil) and
    ((pt.WordType in IdentifierTypes) or (pt.TokenType in FUDGE_NAMES));
end;

function IsIdentifier(const pt: TSourceToken): boolean;
begin
  Result := IsIdentifierToken(pt);

  if Result then
    Result := pt.HasParentNode(nIdentifier, 1);
end;


function IsHintDirective(const pt: TSourceToken): boolean;
begin
  Result := (pt <> nil) and (pt.TokenType in HintDirectives);

  if Result then
    Result := pt.HasParentNode(nHintDirectives, 1);
end;

function HashLiteral(const pt: TSourceToken): boolean;
begin
  Result := (pt.TokenType = ttLiteralString) and (StrLeft(pt.SourceCode, 1) = '#');
end;


end.
