unit Warning;

interface

uses BaseVisitor, ConvertTypes;

type
  TWarning = class(TBaseTreeNodeVisitor)
    private
      fOnWarning: TStatusMessageProc;

    protected
      procedure SendWarning(const pcNode: TObject; const psMessage: string);

    public
      property OnWarning: TStatusMessageProc read fOnWarning write fOnWarning;
  end;


implementation

uses ParseTreeNode, SourceToken, TokenUtils;

procedure TWarning.SendWarning(const pcNode: TObject; const psMessage: string);
var
  lsMessage, lsProc: string;
  lcToken: TSourceToken;
begin
  lsMessage := psMessage;
  if (pcNode is TSourceToken) then
  begin
    lcToken := TSourceToken(pcNode);
  end
  else if (pcNode is TParseTreeNode) then
  begin
    // use first token under this node for pos
    lcToken := TParseTreeNode(pcNode).FirstSolidLeaf as TSourceToken;
  end
  else
    lcToken := nil;

  if lcToken <> nil then
  begin
    lsMessage := lsMessage  + ' near ' + lcToken.Describe + ' ' + lcToken.DescribePosition;
    lsProc := GetProcedureName(lcToken, True, False);
    if lsProc <> '' then
      lsMessage := lsMessage  + ' in ' + GetBlockType(lcToken) + ' ' + lsProc;
  end;

  if Assigned(fOnWarning) then
    fOnWarning(lsMessage);
end;



end.
