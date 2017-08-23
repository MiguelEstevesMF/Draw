grammar Dreql;

@header {
	import java.util.HashMap;
	import java.util.ArrayList;
	import java.io.*;
}

@members{
	String sql = "";
	HashMap<String,String> typedefs = new HashMap<String,String>();
	HashMap<String,String> types_sql = new HashMap<String,String>();
	HashMap<String,String> creates = new HashMap<String,String>();
	
	public String atrs_rel_n_n(String t1, String a1, String t2, String a2){
		String res = "";
		String s1 = "";
		String s2 = "";
		String cod_t1 = creates.get(t1);
		String cod_t2 = creates.get(t2);
		String[] cod1_split = cod_t1.split(" "); 
		String[] cod2_split = cod_t2.split(" ");
		
		for(int i=0; i<cod1_split.length; i++){ 
			if (cod1_split[i].equals(a1)) { 
				s1=cod1_split[i+1];
			}
			if(cod1_split[i].equals("ENUM")) { 
				s1+=" "+cod1_split[i+1]; break; 
			}
		}
		
		for(int i=0; i<cod2_split.length; i++){ 
			if (cod2_split[i].equals(a2)) { 
				s2=cod2_split[i+1];
			}
			if(cod2_split[i].equals("ENUM")) { 
				s2+=" "+cod2_split[i+1]; break; 
			}
		}
		res = a1+" "+s1;
		res += ","+a2+" "+s2;
		res += ",Foreign Key ("+a1+") references "+t1+"("+a1+")";
		res += ",Foreign Key ("+a2+") references "+t2+"("+a2+")";
		return res;
	}
	
	
	public void atrs_rel_n_1(String t1, String a1, String t2, String a2){
		String tab = creates.get(t1);
		String res = tab.substring(0,tab.length()-3); System.out.println(res);
		
		String s1 = "";
		String cod_t1 = creates.get(t2);
		String[] cod1_split = cod_t1.split(" "); 

		for(int i=0; i<cod1_split.length; i++){ 
			if (cod1_split[i].equals(a1)) { 
				s1=cod1_split[i+1];
			}
			if(cod1_split[i].equals("ENUM")) { 
				s1+=" "+cod1_split[i+1]; break; 
			}
		}
		res += ","+a2+" "+s1;
		res += ",Foreign Key ("+a2+") references "+t2+"("+a2+")";
		creates.put(t1,res);
	}

}


dreql 
@init{ types_sql.put("STR","text"); types_sql.put("INT","int"); types_sql.put("FLOAT","real"); types_sql.put("DATE","date"); }
	:	('typedefs:' typedefs)? ('classes:' classes) ('relations:' relations)? { System.out.println(typedefs); System.out.println(creates); }
	;

typedefs 
	:	(typedef ';')+
	;	

classes : 	(classe ';')+
	;
	
classe 	:	name '=' atribs { creates.put($name.text,"create table "+$name.text+" { "+$atribs.atribs+" };"); }
	;
	
atribs returns [String atribs]	
	:	a=atrib { $atribs = $a.atrib; } (('x'|'X') b=atrib { $atribs += ","+$b.atrib; })*
	;
	
atrib returns [String atrib]
	:	'(' '@' name ')' 
	|	a='!'? '(' type '::' name ')' { $atrib = $name.text+" "+$type.type; if ($a.text!=null) $atrib+=" primary key"; }  	
	;

type returns [String type]
 	:	atomic_type { $type = $atomic_type.type; }
	|	structured_type
	;

structured_type
	:
	;

atomic_type returns [String type]
	:	primitive_type { $type = types_sql.get($primitive_type.text); }
	|	renamed_type { $type = $renamed_type.type; }
	|	enum_type { $type = $enum_type.type; }
	;

primitive_type
	:	'STR' | 'INT' | 'FLOAT' | 'DATE'
	;

renamed_type returns [String type]
	:	name { $type = typedefs.get($name.text); }
	;

enum_type returns [String type]
	:	'{' a=name { $type = "ENUM ('"+$a.text+"'"; } (',' b=name { $type += ","+"'"+$b.text+"'"; })* '}' { $type += ")"; }
	;
	
typedef :	name '::' type { typedefs.put($name.text,$type.type); }
	;
	
	
relations : 	(relation ';')+
	;

relation
	:	t1=name a1=name '(' (m1='n'|m2='1') ')' '<->' t2=name a2=name '(' (m3='n'|m4='1') ')' 
		{ 
			if ($m1.text!=null && $m3.text!=null) { creates.put($t1.text+"_"+$t2.text,"create table "+$t1.text+"_"+$t2.text+"{"+atrs_rel_n_n($t1.text,$a1.text,$t2.text,$a2.text)+"};"); }
			if ($m2.text!=null && $m3.text!=null) { atrs_rel_n_1($t2.text,$a2.text,$t1.text,$a1.text); }
			if ($m1.text!=null && $m4.text!=null) { atrs_rel_n_1($t1.text,$a1.text,$t2.text,$a2.text); }

		} 
	;

name 	:	STR
	;

STR 	:	('a'..'z'|'A'..'Z')+
	;
	
WS	:	(' ' | '\t' | '\n' | '\r') { $channel=HIDDEN; }
	;

