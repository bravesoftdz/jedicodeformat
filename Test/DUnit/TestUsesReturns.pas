unit TestUsesReturns;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code

The Original Code is TestUsesReturns, released Sept 2003.
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
{ test the feature of adding returns
  after each item in the uses clause }

interface

uses
  Classes,
  TestFrameWork,
  StringsConverter, BaseTestProcess;

type
  TTestUsesReturns = class(TBaseTestProcess)
  private

  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure Test0;
    procedure Test1;
    procedure Test2;
    procedure Test3;
    procedure TestComment1;
    procedure TestComment2;
  end;

implementation

uses
  SysUtils,
  JclStrings,
  JcfRegistrySettings, JcfSettings, TestConstants, ReturnAfter;

procedure TTestUsesReturns.Setup;
begin
  inherited;

  InitTestSettings;
  FormatSettings.Returns.UsesClauseOnePerLine := True;
end;

procedure TTestUsesReturns.TearDown;
begin
  inherited;
  FormatSettings.Returns.UsesClauseOnePerLine := False;
end;

procedure TTestUsesReturns.Test0;
const
  IN_UNIT_TEXT = UNIT_HEADER + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);
end;

procedure TTestUsesReturns.Test1;
const
  IN_UNIT_TEXT = UNIT_HEADER + ' uses foo; ' + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + AnsiLineBreak +
    ' uses' + AnsiLineBreak + ' foo;' + AnsiLineBreak + ' ' + UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);
end;

procedure TTestUsesReturns.Test2;
const
  IN_UNIT_TEXT = UNIT_HEADER + ' uses foo, bar; ' + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + AnsiLineBreak +
    ' uses' + AnsiLineBreak +
    ' foo,' + AnsiLineBreak +
    ' bar;' + AnsiLineBreak + ' ' +
    UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);
end;

procedure TTestUsesReturns.Test3;
const
  IN_UNIT_TEXT = UNIT_HEADER + ' uses foo, bar, fish; ' + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + AnsiLineBreak +
    ' uses' + AnsiLineBreak +
    ' foo,' + AnsiLineBreak +
    ' bar,' + AnsiLineBreak +
    ' fish;' + AnsiLineBreak + ' ' + UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);
end;



procedure TTestUsesReturns.TestComment1;
const
  IN_UNIT_TEXT = UNIT_HEADER + ' uses foo {foo}, bar, fish; ' + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + AnsiLineBreak +
    ' uses' + AnsiLineBreak +
    ' foo {foo},' + AnsiLineBreak +
    ' bar,' + AnsiLineBreak +
    ' fish;' + AnsiLineBreak + ' ' + UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);
end;

procedure TTestUsesReturns.TestComment2;
const
  IN_UNIT_TEXT = UNIT_HEADER + ' uses foo, {foo} bar, fish; ' + UNIT_FOOTER;
  OUT_UNIT_TEXT = SPACED_UNIT_HEADER + AnsiLineBreak +
    ' uses' + AnsiLineBreak +
    ' foo, {foo} bar,' + AnsiLineBreak +
    ' fish;' + AnsiLineBreak + ' ' + UNIT_FOOTER;
begin
  TestProcessResult(TReturnAfter, IN_UNIT_TEXT, OUT_UNIT_TEXT);end;

initialization
 TestFramework.RegisterTest('Processes', TTestUsesReturns.Suite);
end.