unit RemoveReturn;

interface

uses BaseVisitor, VisitParseTree;

type
  TRemoveReturn = class(TBaseTreeNodeVisitor)
    public
      procedure VisitSourceToken(const pcNode: TObject; var prVisitResult: TRVisitResult); override;
  end;



implementation

uses ParseTreeNode, SourceToken, TokenType, ParseTreeNodeType;

procedure TRemoveReturn.VisitSourceToken(const pcNode: TObject; var prVisitResult: TRVisitResult);
var
  lcSourceToken: TSourceToken;
begin
  lcSourceToken := TSourceToken(pcNode);

  { not in asm }
  if lcSourceToken.HasParentNode(nAsm) then
    exit;

  // transmute to white space  - may be needed as seperator
  if lcSourceToken.TokenType = ttReturn then
  begin
    lcSourceToken.SourceCode := ' ';
    lcSOurceToken.TokenType := ttWhiteSpace;
  end;
end;

end.
