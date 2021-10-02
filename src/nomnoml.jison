%lex
%%

\s*\|\s*                          return '|'
(\\(\[|\]|\|)|[^\]\[|;\n])+       return 'IDENT'
"["                               return '['
\s*\]                             return ']'
[ ]*(\;|\n)+[ ]*                  return 'SEP'
<<EOF>>                           return 'EOF'
.                                 return 'INVALID'

/lex

%start root

%% /* ------------------------------------------------- */

root
    : compartment EOF      { return $1 }
    | SEP compartment EOF  { return $2 }
    | SEP compartment SEP EOF { return $2 }
    | compartment SEP EOF  { return $1 };

slot
  : IDENT                  {$$ = $1.trim().replace(/\\(\[|\]|\|)/g, '$'+'1');}
  | class                  {$$ = $1;}
  | association            {$$ = $1;};

compartment
  : slot                   {$$ = [$1];}
  | compartment SEP slot   {$$ = $1.concat($3);};

parts
  : compartment            {$$ = [$1];}
  | parts '|' compartment  {$$ = $1.concat([$3]);}
  | parts '|'              {$$ = $1.concat([[]]);};

association
  : class IDENT class      {
           var t = $2.trim().replace(/\\(\[|\]|\|)/g, '$'+'1').match('^(.*?)([)<:o+(]*[-_]/?[-_]*[):o+>(]*)(.*)$');
           if (!t) {
             throw new Error('line '+@3.first_line+': Classifiers must be separated by a relation or a line break')
           }
           $$ = {assoc:t[2], start:$1, end:$3, startLabel:t[1].trim(), endLabel:t[3].trim()};
  };

class
  : '[' parts ']'          {
           var type = 'CLASS';
           var id = $2[0][0];
           var metadata = {}
           var typeMatch = $2[0][0].match('^\s*<([a-z]*)([^>]*)>(.*)');
           if (typeMatch) {
               type = typeMatch[1].toUpperCase();
               if (typeMatch[2]) {
                 metadata = typeMatch[2].trim().split(' ').reduce((accum, nameAndValue) => {
                   var attrMatch = nameAndValue.trim().match('(id|class|href|target)\s*=\s*[\'"]([^\'"]*)[\'"]');
                   return attrMatch ? { ...accum, [attrMatch[1] !== 'class' ? attrMatch[1] : 'className']: attrMatch[2] } : accum 
                 }, {})
               }
               id = typeMatch[3].trim();
           }
           $2[0][0] = id;
           $$ = {type:type, metadata:metadata, id:id, parts:$2};
  };
