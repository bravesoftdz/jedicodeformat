{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is frClarify.pas, released April 2000.
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

unit frClarify;

interface

uses
  { delphi }
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls,
  { local}
  frmBaseSettingsFrame;

type
  TfClarify = class(TfrSettingsFrame)
    cbWarnings: TCheckBox;
    rgRunOnceOffs: TRadioGroup;
  private

  public
    constructor Create(AOwner: TComponent); override;

    procedure Read; override;
    procedure Write; override;

  end;

implementation

{$R *.DFM}

uses JcfSettings, TokenType, JCFHelp, SetClarify;

constructor TfClarify.Create(AOwner: TComponent);
begin
  inherited;
  fiHelpContext := HELP_CLARIFY;
end;


{-------------------------------------------------------------------------------
  worker procs }

procedure TfClarify.Read;
begin
  with FormatSettings.Clarify do
  begin
    rgRunOnceOffs.ItemIndex := Ord(OnceOffs);
    cbWarnings.Checked := Warnings;
  end;
end;

procedure TfClarify.Write;
begin
  with FormatSettings.Clarify do
  begin
    OnceOffs := TOnceOffsOption(rgRunOnceOffs.ItemIndex);
    Warnings := cbWarnings.Checked;
  end;
end;

{-------------------------------------------------------------------------------
  event handlers }

end.
