/*
 * redcloth_inline.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
#include <ruby.h>
#include "redcloth.h"

%%{

  machine redcloth_inline;
  include redcloth_common "redcloth_common.rl";

  # links
  mtext_noquotes = mtext -- '"' ;
  quoted_mtext = '"' mtext_noquotes '"' ;
  mtext_including_quotes = (mtext_noquotes ' "' mtext_noquotes '" ' mtext_noquotes?)+ ;
  link_says = ( C_noactions "."* " "* ((quoted_mtext | mtext_including_quotes | mtext_noquotes) -- '":') ) >A %{ STORE(link_text); } ;
  link_says_noquotes_noactions = ( C_noquotes_noactions "."* " "* ((mtext_noquotes) -- '":') ) ;
  link = ( '"' link_says '":' %A uri %{ STORE_URL(href); } ) >X ;
  link_noquotes_noactions = ( '"' link_says_noquotes_noactions '":' uri ) ;
  bracketed_link = ( '["' link_says '":' %A uri %{ STORE(href); } :> "]" ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE(src) } ;
  image_is = ( A2 C ". "? image_src :> title? ) ;
  image_link = ( ":" uri >A %{ STORE_URL(href); } ) ;
  image = ( "["? "!" image_is "!" %A image_link? "]"? ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  end_markup_phrase = (" " | PUNCT | EOF | LF) @{ fhold; };
  code = "["? "@" >X mtext >A %T :> "@" "]"? ;
  code_tag_start = "<code" [^>]* ">" ;
  code_tag_end = "</code>" ;
  script_tag = ( "<script" [^>]* ">" (default+ -- "</script>") "</script>" LF? ) >X >A %T ;
  notextile = "<notextile>" >X (default+ -- "</notextile>") >A %T "</notextile>";
  strong = "["? "*" >X mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X mtext >A %T :> "**" "]"? ;
  em = "["? "_" >X mtext >A %T :> "_" "]"? ;
  i = "["? "__" >X mtext >A %T :> "__" "]"? ;
  del = "[-" >X C ( mtext ) >A %T :>> "-]" ;
  emdash_parenthetical_phrase_with_spaces = " -- " mtext " -- " ;
  del_phrase = (( " " >A %{ STORE(beginning_space); } "-") >X C ( mtext ) >A %T :>> ( "-" end_markup_phrase )) - emdash_parenthetical_phrase_with_spaces ;
  ins = "["? "+" >X mtext >A %T :> "+" "]"? ;
  sup = "[^" >X mtext >A %T :> "^]" ;
  sup_phrase = ( "^" when starts_phrase) >X ( mtext ) >A %T :>> ( "^" end_markup_phrase ) ;
  sub = "[~" >X mtext >A %T :> "~]" ;
  sub_phrase = ( "~" when starts_phrase) >X ( mtext ) >A %T :>> ( "~" end_markup_phrase ) ;
  span = "[%" >X mtext >A %T :> "%]" ;
  span_phrase = (("%" when starts_phrase) >X ( mtext ) >A %T :>> ( "%" end_markup_phrase )) ;
  cite = "["? "??" >X mtext >A %T :> "??" "]"? ;
  ignore = "["? "==" >X %A mtext %T :> "==" "]"? ;
  snip = "["? "```" >X %A mtext %T :> "```" "]"? ;
  
  # quotes
  quote1 = "'" >X %A mtext %T :> "'" ;
  non_quote_chars_or_link = (chars -- '"') | link_noquotes_noactions ;
  mtext_inside_quotes = ( non_quote_chars_or_link (mspace non_quote_chars_or_link)* ) ;
  html_tag_up_to_attribute_quote = "<" Name space+ NameAttr space* "=" space* ;
  quote2 = ('"' >X %A ( mtext_inside_quotes - (mtext_inside_quotes html_tag_up_to_attribute_quote ) ) %T :> '"' ) ;
  multi_paragraph_quote = (('"' when starts_line) >X  %A ( chars -- '"' ) %T );
  
  # html
  start_tag = ( "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">" ) >X >A %T ;
  empty_tag = ( "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ) >X >A %T ;
  end_tag = ( "</" Name space* ">" ) >X >A %T ;
  html_comment = ("<!--" (default+) :>> "-->") >X >A %T;

  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = "--" ;
  arrow = "->" ;
  endash = " - " ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE(title) } :> ")" ) >X ;
  caps_noactions = upper{3,} ;
  caps = ( caps_noactions >A %*T ) >X ;
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | ( alpha ( alpha | digit )+ ) ) %T ';' ) >X ;
  
  # info
  redcloth_version = "[RedCloth::VERSION]" ;

  other_phrase = phrase -- dim_noactions;

  code_tag := |*
    code_tag_end { CAT(block); fgoto main; };
    default => esc_pre;
  *|;

  main := |*
    
    image { INLINE(block, image); };
    
    link { PARSE_LINK_ATTR(link_text); PASS(block, name, link); };
    bracketed_link { PARSE_LINK_ATTR(link_text); PASS(block, name, link); };
    
    code { PARSE_ATTR(text); PASS_CODE(block, text, code, opts); };
    code_tag_start { CAT(block); fgoto code_tag; };
    notextile { INLINE(block, notextile); };
    strong { PARSE_ATTR(text); PASS(block, text, strong); };
    b { PARSE_ATTR(text); PASS(block, text, b); };
    em { PARSE_ATTR(text); PASS(block, text, em); };
    i { PARSE_ATTR(text); PASS(block, text, i); };
    del { PASS(block, text, del); };
    del_phrase { PASS(block, text, del_phrase); };
    ins { PARSE_ATTR(text); PASS(block, text, ins); };
    sup { PARSE_ATTR(text); PASS(block, text, sup); };
    sup_phrase { PARSE_ATTR(text); PASS(block, text, sup_phrase); };
    sub { PARSE_ATTR(text); PASS(block, text, sub); };
    sub_phrase { PARSE_ATTR(text); PASS(block, text, sub_phrase); };
    span { PARSE_ATTR(text); PASS(block, text, span); };
    span_phrase { PARSE_ATTR(text); PASS(block, text, span_phrase); };
    cite { PARSE_ATTR(text); PASS(block, text, cite); };
    ignore => ignore;
    snip { PASS(block, text, snip); };
    quote1 { PASS(block, text, quote1); };
    quote2 { PASS(block, text, quote2); };
    multi_paragraph_quote { PASS(block, text, multi_paragraph_quote); };
    
    ellipsis { INLINE(block, ellipsis); };
    emdash { INLINE(block, emdash); };
    endash { INLINE(block, endash); };
    arrow { INLINE(block, arrow); };
    caps { INLINE(block, caps); };
    acronym { INLINE(block, acronym); };
    dim { INLINE(block, dim); };
    trademark { INLINE(block, trademark); };
    registered { INLINE(block, registered); };
    copyright { INLINE(block, copyright); };
    footno { PASS(block, text, footno); };
    entity { INLINE(block, entity); };
    
    script_tag { INLINE(block, inline_html); };
    start_tag { INLINE(block, inline_html); };
    end_tag { INLINE(block, inline_html); };
    empty_tag { INLINE(block, inline_html); };
    html_comment { INLINE(block, inline_html); };
    
    redcloth_version { INLINE(block, inline_redcloth_version); };
    
    other_phrase => esc;
    PUNCT => esc;
    space => esc;
    
    EOF;
    
  *|;

}%%

%% write data nofinal;

VALUE
red_pass(VALUE self, VALUE regs, VALUE ref, ID meth, VALUE refs)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) rb_hash_aset(regs, ref, redcloth_inline2(self, txt, refs));
  return rb_funcall(self, meth, 1, regs);
}

VALUE
red_parse_attr(VALUE self, VALUE regs, VALUE ref)
{
  VALUE txt = rb_hash_aref(regs, ref);
  VALUE new_regs = redcloth_attributes(self, txt);
  return rb_funcall(regs, rb_intern("update"), 1, new_regs);
}

VALUE
red_parse_link_attr(VALUE self, VALUE regs, VALUE ref)
{
  VALUE txt = rb_hash_aref(regs, ref);
  VALUE new_regs = redcloth_link_attributes(self, txt);
  return rb_funcall(regs, rb_intern("update"), 1, new_regs);
}

VALUE
red_pass_code(VALUE self, VALUE regs, VALUE ref, ID meth)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) {
    VALUE txt2 = rb_str_new2("");
    rb_str_cat_escaped_for_preformatted(self, txt2, RSTRING_PTR(txt), RSTRING_PTR(txt) + RSTRING_LEN(txt));
    rb_hash_aset(regs, ref, txt2);
  }
  return rb_funcall(self, meth, 1, regs);
}

VALUE
red_block(VALUE self, VALUE regs, VALUE block, VALUE refs)
{
  ID method;
  VALUE fallback;
  VALUE sym_text = ID2SYM(rb_intern("text"));
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if ((!NIL_P(block)) && !NIL_P(btype))
  {
    method = rb_intern(RSTRING_PTR(btype));
    if (method == rb_intern("notextile")) {
      rb_hash_aset(regs, sym_text, block);
    } else {
      rb_hash_aset(regs, sym_text, redcloth_inline2(self, block, refs));
    }
    if (rb_respond_to(self, method)) {
      block = rb_funcall(self, method, 1, regs);
    } else {
      fallback = rb_hash_aref(regs, ID2SYM(rb_intern("fallback")));
      if (!NIL_P(fallback)) {
        rb_str_append(fallback, rb_hash_aref(regs, sym_text));
        CLEAR_REGS();
        rb_hash_aset(regs, sym_text, fallback);
      }
      block = rb_funcall(self, rb_intern("p"), 1, regs);
    }
  }
  return block;
}

VALUE
red_blockcode(VALUE self, VALUE regs, VALUE block)
{
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if (RSTRING_LEN(block) > 0)
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
    block = rb_funcall(self, rb_intern(RSTRING_PTR(btype)), 1, regs);
  }
  return block;
}

void
red_inc(VALUE regs, VALUE ref)
{
  int aint = 0;
  VALUE aval = rb_hash_aref(regs, ref);
  if (aval != Qnil) aint = NUM2INT(aval);
  rb_hash_aset(regs, ref, INT2NUM(aint + 1));
}

VALUE
redcloth_inline(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  int cs, act;
  char *ts, *te, *reg, *eof;
  char *orig_p = p, *orig_pe = pe;
  VALUE block = rb_str_new2("");
  VALUE regs = Qnil;
  unsigned int opts = 0;
  VALUE buf = Qnil;
  
  %% write init;

  %% write exec;

  return block;
}

/** Append characters to a string, escaping (&, <, >, ", ') using the formatter's escape method.
  * @param str ruby string
  * @param ts  start of character buffer to append
  * @param te  end of character buffer
  */
void
rb_str_cat_escaped(self, str, ts, te)
  VALUE self, str;
  char *ts, *te;
{
  VALUE source_str = rb_str_new(ts, te-ts);
  VALUE escaped_str = rb_funcall(self, rb_intern("escape"), 1, source_str);
  rb_str_concat(str, escaped_str);
}

void
rb_str_cat_escaped_for_preformatted(self, str, ts, te)
  VALUE self, str;
  char *ts, *te;
{
  VALUE source_str = rb_str_new(ts, te-ts);
  VALUE escaped_str = rb_funcall(self, rb_intern("escape_pre"), 1, source_str);
  rb_str_concat(str, escaped_str);
}

VALUE
redcloth_inline2(self, str, refs)
  VALUE self, str, refs;
{
  StringValue(str);
  return redcloth_inline(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, refs);
}
