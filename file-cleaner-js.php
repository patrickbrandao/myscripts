#!/usr/bin/php -q
<?php

// Limpador de arquivos JavaScript

// Variaveis
	// Arquivo de entrada
	$INPUT_FILE = '';

	// Arquivo de saida
	$OUTPUT_FILE = '';

	// Alterar o arquivo de entrada (perigoso, perda de dados)
	$INLINE = 0;

	// Ativar DEBUG durante acoes (level)
	$DEBUG = 0;

	// Finalizar conteudo com uma quebra de linha
	$INSERT_FINAL_BREAK = 0;

// Funcoes
	function _abort($error, $errno=1){
		global $INPUT_FILE ;
		echo "\n";
		echo "FILE-CLEANER-JS ABORTED [", $INPUT_FILE, "] ERROR: ", $error, "\n";
		echo "\n";
		exit($errno);
	}

	function _help(){
		echo "\n";
		echo "Use: file-cleaner-js [options] -f (file) [-w (output-file)]\n";
		echo "\n";
		echo " -f (file)    Arquivo de entrada\n";
		echo " -w (file)    Arquivo de saida\n";
		echo " -i           Grava resultado no mesmo arquivo de entrada (sem -w)\n";
		echo " -B           Adicionar quebra de linha ao final do arquivo";
		echo "\n";
		exit(0);
	}

//---------------------------------------------------------------------- *************** JAVASCRIPT

	// Funcoes para tratar sintaxe e interpretaçao de javascript em php
	
	// remover quando primeiro byte for numerico
	function jgetname($iname, $_id){
		$map = array(
			'0' => '_',	// _
			'1' => 'h',	// h
			'2' => 'i',	// i
			'3' => 'j',	// j
			'4' => 'k',	// k
			'5' => 'l',	// l
			'6' => 'm',	// m
			'7' => 'n',	// n
			'8' => 'o',	// o
			'9' => 'p',	// p
			'a' => 'q',	// q
			'b' => 'r',	// r
			'c' => 's',	// s
			'd' => 't',	// t
			'e' => 'u',	// u
			'f' => 'v',	// v

			'10' => 'x',
			'11' => 'z',
			'12' => 'w',
			'13' => 'y',
			'14' => 'a',
			'15' => 'b',
			'16' => 'c',
			'17' => 'd',
			'18' => 'e',
			'19' => 'f',
			'1a' => 'g',
			'1b' => 'k1',
			'1c' => 'k2',
			'1d' => 'k3',
			'1e' => 'k4',
			'1f' => 'k5',
			'20' => 'k6',
			'21' => 'k7',
			'22' => 'k8',
			'23' => 'k9',
			'24' => 'ka',
			'25' => 'kb',
			'26' => 'kc',
			'27' => 'kd',
			'28' => 'ke',
			'29' => 'kf',
			'2a' => 'kg',
			'2b' => 'kh',
			'2c' => 'ki',
			'2d' => 'kj',
			'2e' => 'kk',
			'2f' => 'kl',
			'30' => 'km',
			'31' => 'kn',
			'32' => 'ko',
			'33' => 'kp',
			'34' => 'kq',
			'35' => 'kr',
			'36' => 'ks',
			'37' => 'kt',
			'38' => 'ku',
			'39' => 'kv',
			'3a' => 'kx',
			'3b' => 'kz',
			'3e' => 'kw',
			'3f' => 'ky',
			'40' => 'g0',
			'41' => 'g1',
			'42' => 'g2',
			'43' => 'g3',
			'44' => 'g5',
			'45' => 'g7',
			'46' => 'g8',
			'47' => 'g9',
			'48' => 'ga',
			'49' => 'gb',
			'4a' => 'gc',
			'4b' => 'gd',
			'4c' => 'ge',
			'4d' => 'gf',
			'4e' => 'gg',
			'4f' => 'gh',
			'50' => 'gi',
			'51' => 'gj',
			'52' => 'gk',
			'53' => 'gl',
			'54' => 'gm',
			'55' => 'gn',
			'56' => 'go',
			'57' => 'gp',
			'58' => 'gq',
			'59' => 'gr',
			'5a' => 'gs',
			'5b' => 'gt',
			'5c' => 'gu',
			'5d' => 'gv',
			'5e' => 'gw',
			'5f' => 'gy',
			'60' => 'gx',
			'61' => 'gz',

			'62' => 'h0',
			'63' => 'h1',
			'64' => 'h2',
			'65' => 'h3',
			'66' => 'h5',
			'67' => 'h7',
			'68' => 'h8',
			'69' => 'h9',
			'6a' => 'ha',
			'6b' => 'hb',
			'6c' => 'hc',
			'6d' => 'hd',
			'6e' => 'he',
			'6f' => 'hf',
			'70' => 'hg',
			'71' => 'hh',
			'72' => 'hi',
			'73' => 'hj',
			'74' => 'hk',
			'75' => 'hl',
			'76' => 'hm',
			'77' => 'hn',
			'78' => 'ho',
			'79' => 'hp',
			'7a' => 'hq',
			'7b' => 'hr',
			'7c' => 'hs',
			'7d' => 'ht',
			'7e' => 'hu',
			'7f' => 'hv',
			'80' => 'hw',
			'81' => 'hy',
			'82' => 'hx',
			'83' => 'hz',

			'84' => 'i0',
			'85' => 'i1',
			'86' => 'i2',
			'87' => 'i3',
			'88' => 'i5',
			'89' => 'i7',
			'8a' => 'i8',
			'8b' => 'i9',
			'8c' => 'ia',
			'8d' => 'ib',
			'8e' => 'ic',
			'8f' => 'id',
			'90' => 'ie',
			'91' => 'if',
			'92' => 'ig',
			'93' => 'ih',
			'94' => 'ii',
			'95' => 'ij',
			'96' => 'ik',
			'97' => 'il',
			'98' => 'im',
			'99' => 'in',
			'9a' => 'io',
			'9b' => 'ip',
			'9c' => 'iq',
			'9d' => 'ir',
			'9e' => 'is',
			'9f' => 'it',
			'a0' => 'iu',
			'a1' => 'iv',
			'a2' => 'iw',
			'a3' => 'iy',
			'a4' => 'ix',
			'a5' => 'iz'
		);
		//$_id++;
		$hid = dechex($_id);
		
		// achado no mapa simples
		if(isset($map[$hid])) return($map[$hid]);
		
		// combinacao, mapa composto
		$hid = str_replace(array_keys($map), array_values($map), $hid);
		$name = $hid;
		return($name);
	}

	// tokenize de javascript - transforma codigo fonte javascript em pedaços identificados

	// mapa de strings mais comuns a serem substituidas por variaveis
		$strmap = array();
		$strmap[''] = 'A';				//  567
		$strmap['object'] = '_1';		//  258
		$strmap['string'] = '_2';		//  113
		$strmap['function'] = '_3';		//  105
		//$strmap["'"] = 'B';			//  53
		$strmap['boolean'] = '_4';		//  48
		//$strmap['0'] = 'C';			//  46
		$strmap['undefined'] = '_5';	//  45
		$strmap[' '] = 'D';				//  40
		$strmap['number'] = '_6';		//  35
		$strmap[';'] = 'E';				//  32

		$strmap['jtable'] = '_7';		//  10
		$strmap['uajax'] = '_8';		//  19
		$strmap['udialog'] = '_9';		//  10
		$strmap['wide'] = '_a';			//  14
		$strmap['json'] = '_b';			//  28
		$strmap['xhr'] = '_c';			//  17
		$strmap['html'] = '_d';			//  11
		$strmap['text'] = '_e';			//  22

		$strmap['px'] = 'F';			//  14
		$strmap['left'] = '_f';			//  17
		$strmap['right'] = '_g';		//  10
		$strmap['float'] = '_h';		//  12
		$strmap['div'] = '_i';			//  10
		$strmap['id'] = 'G';			//  12
		$strmap['style'] = '_j';		//  11
		$strmap['class'] = '_k';		//  12

		$strmap['url'] = 'H'; //  12
		$strmap['time'] = '_m'; //  10

		$strmap['100%'] = 'I'; //  13
		$strmap['iframe'] = '_n'; //  12
		$strmap['list'] = 'J'; //  10

		$strmap['onclick'] = '_o'; //  10
		$strmap['static'] = '_p'; //  11
		$strmap['box'] = 'K'; //  23
		$strmap['linear'] = '_q'; //  17
		$strmap['radial'] = '_r'; //  10

		$strmap['me'] = '_s'; //  11
		$strmap['px;'] = '_t'; //  10

		$strmap[', '] = '_u'; //  23
		$strmap['" id="'] = '_v'; //  10
		$strmap['"></div>'] = '_x'; //  23
		$strmap['">'] = '_z'; //  30
		$strmap['</span>'] = '_w'; //  10
		$strmap['</div>'] = '_y'; //  56
		$strmap['<div id="'] = '_A'; //  14
		$strmap['</tr>'] = '_B'; //  12
		$strmap[');'] = '_C'; //  12

		$strmap['onmouseover'] = '_D';//  +
		$strmap['onmousedown'] = '_E';//  +
		$strmap['onmouseout'] = '_F'; //  +
		$strmap['onmouseup'] = '_G';  //  +
		$strmap['ondblclick'] = '_H'; //  +

		$strmap['jchart'] = '_I'; // +
		$strmap['jframe'] = '_J'; // +
		$strmap['jframe_frm'] = '_K'; // +
		$strmap['jmainmenu'] = '_L'; // +
		$strmap['jgauge'] = '_M'; // +
		$strmap['jmap'] = '_N'; // +
		$strmap['jprogress'] = '_O'; // +
		$strmap['jslider'] = '_P'; // +
		$strmap['jsmenu'] = '_Q'; // +
		$strmap['jstab'] = '_R'; // +
		$strmap['jstab_tabs'] = '_S'; // +
		$strmap['jstree'] = '_T'; // +

		$strmap['jwtable'] = '_U'; // +
		$strmap['ubuttons'] = '_V'; // +
		$strmap['uform'] = '_X'; // +
		$strmap['unotify'] = '_Y'; // +
		$strmap['loopback'] = '_W'; // +

		$strmap['">&nbsp;<br></td>'] = 'L'; //  13

		$strmap[','] = 'M'; //  20
		//$strmap['.'] = 'N';//  10
		$strmap['='] = 'O'; //  13
		$strmap['%'] = 'P'; //  14
		$strmap['"'] = 'Q'; //  18
		$strmap[':'] = 'R'; //  21
		$strmap[')'] = 'S'; //  23
		$strmap['/'] = 'T'; //  19
		$strmap['F'] = 'U'; //  11
		$strmap['s'] = 'V'; //  14
		$strmap['$'] = 'X'; //  13
		$strmap['-'] = 'Z'; //  27
		$strmap['_'] = 'W'; //  14
		$strmap['>'] = 'Y'; //  11

	// dicionario de codigo do token e nome utilizado para registra-lo
	$jdict = array();


// cadastro de palavras chaves
	$jreserved_ctrl = array(
		80 => 'while',
		81 => 'for',
		82 => 'else'
	);

	$jreserved = array(
	
		// palavras reservadas
		100 => 'abstract',
		102 => 'as',
		104 => 'boolean',
		106 => 'break',
		108 => 'byte',
		110 => 'case',
		112 => 'catch',
		114 => 'char',
		116 => 'class',
		118 => 'continue',
		119 => 'const',
		120 => 'debugger',
		122 => 'default',
		124 => 'delete',
		126 => 'do',
		128 => 'double',
		130 => 'else',
		132 => 'enum',
		134 => 'export',
		136 => 'extends',
		138 => 'false',
		140 => 'final',
		142 => 'finally',
		144 => 'float',
		146 => 'for',
		148 => 'function',
		150 => 'goto',
		152 => 'if',
		154 => 'implements',
		156 => 'import',
		158 => 'in',
		160 => 'instanceof',
		162 => 'int',
		164 => 'interface',
		166 => 'is',
		168 => 'long',
		170 => 'namespace',
		172 => 'native',
		174 => 'new',
		176 => 'null',
		178 => 'package',
		180 => 'private',
		182 => 'protected',
		184 => 'public',
		186 => 'return',
		188 => 'short',
		190 => 'static',
		192 => 'super',
		194 => 'switch',
		196 => 'synchronized',
		198 => 'this',
		200 => 'throw',
		202 => 'throws',
		204 => 'transient',
		206 => 'true',
		208 => 'try',
		210 => 'typeof',
		212 => 'use',
		214 => 'var',
		216 => 'void',
		218 => 'volatile',
		220 => 'while',
		222 => 'with',
	
		// palavras pre-definidas
		400 => 'Anchor',
		410 => 'anchors',
		420 => 'Applet',
		430 => 'applets',
		440 => 'Area',
		450 => 'Array',
		460 => 'Body',
		470 => 'Button',
		480 => 'Checkbox',
		490 => 'Date',
		500 => 'document',
		501 => 'body',
		510 => 'Error',
		520 => 'EvalError',
		530 => 'FileUpload',
		540 => 'Form',
		550 => 'forms',
		560 => 'frame',
		570 => 'frames',
		580 => 'Function',
		590 => 'Hidden',
		600 => 'History',
		610 => 'history',
		620 => 'Image',
		630 => 'images',
		640 => 'Link',
		650 => 'links',
		660 => 'location',
		670 => 'Math',
		680 => 'MimeType',
		690 => 'mimetypes',
		700 => 'navigator',
		710 => 'Number',
		720 => 'Object',
		730 => 'Option',
		740 => 'options',
		750 => 'Password',
		760 => 'Plugin',
		770 => 'plugins',
		780 => 'Radio',
		790 => 'RangeError',
		800 => 'ReferenceError',
		810 => 'RegExp',
		820 => 'Reset',
		830 => 'screen',
		840 => 'Script',
		850 => 'Select',
		860 => 'String',
		870 => 'Style',
		880 => 'StyleSheet',
		890 => 'Submit',
		900 => 'SyntaxError',
		910 => 'Text',
		920 => 'Textarea',
		930 => 'TypeError',
		940 => 'URIError',
		950 => 'window',

		// propriedades e eventos padroes
		1200 => 'constructor',
		1210 => 'prototype',
		1230 => 'Methods',

		1240 => 'hasOwnProperty',
		1250 => 'isPrototypeOf',
		1260 => 'propertyIsEnum',
		1270 => 'tostring',
		1280 => 'valueof',
		
		// palavras reservadas de outras linguagnes, perigo de confundir
		1400 => 'define',
		1410 => 'include',
		1420 => 'endif',
		1430 => 'elif',
		1440 => 'defined',
		1450 => 'undef',
		1460 => 'error',
		1470 => 'warning',
		1480 => 'pragma',
		1490 => 'clone',
		1500 => 'empty',
		1510 => 'global',

		// variaveis de pre-compilacao	
		1600 => '__DATE__',
		1610 => '__TIME__',
		1620 => '__TS__',
		1630 => '__DATETIME__',
		
		// propriedades de objetos pre-definidos
		1640 => 'innerWidth',
		1641 => 'innerHeight',
		1642 => 'offsetWidth',
		1643 => 'offsetHeight',
		1644 => 'clientWidth',
		1645 => 'clientHeight',
		1646 => 'documentElement'
	);
	// publicar como constante as palavras reservadas
	foreach($jreserved as $kid=>$word){
		//define('j_'.$word, $kid);
		$jdict[$kid] = 'j_'.$word;
	}

	// controle de escopo
	$jbasics = array(
		1 => array('(', 'j_open_param'),
		2 => array(')', 'j_close_param'),
		3 => array('{', 'j_open_block'),
		4 => array('}', 'j_close_block'),
		5 => array('[', 'j_open_key'),
		6 => array(']', 'j_close_key'),
		7 => array('.', 'j_dot'),
		8 => array(',', 'j_virg'),
		9 => array(';', 'j_separator'),
		10 => array('@', 'j_arroba'),
		11 => array('=', 't_equal'),
		12 => array('&', 't_ee'),
		13 => array('!', 't_doinvert'),
		14 => array('*', 't_mmultiplier'),
		15 => array('-', 't_mminus'),
		16 => array('<', 't_cmp_small'),
		17 => array('>', 't_cmp_large'),
		18 => array('?', 't_intor'),
		19 => array(':', 't_double_dot'),
		20 => array('+', 't_mplus'),
		21 => array('%', 't_mrest'),
		22 => array('^', 't_melev'),
		23 => array('/', 't_mdiv'),
		24 => array('\\', 't_escapechar'),
		25 => array('~', 't_til'),
		26 => array('|', 't_orbit')

	);
	foreach($jbasics as $kid=>$a) $jdict[$kid] = $a[1];
	
	// comparadores ou operadores duplos/tripols
	$joperators = array(
		3000 => array('===', 't_is_identical'),
		3010 => array('!==', 't_is_not_identical'),
		3030 => array('<<=', 't_bin_sl_equal'),
		3040 => array('>>=', 't_bin_sr_equal'),

		3060 => array('&=', 't_and_equal'),
		3070 => array('&&', 't_and_cmp'),
		3080 => array('||', 't_or_cmp'),
		3100 => array('==', 't_is_equal'),
		3110 => array('>=', 't_is_gt_or_equal'),
		3120 => array('<=', 't_is_sm_or_equal'),
		3130 => array('!=', 't_is_not_equal'),
		3140 => array('<>', 't_is_not_equal_old'),
		3150 => array('-=', 't_minus_equal'),
		3160 => array('+=', 't_plus_equal'),
		3170 => array('++', 't_increment'),
		3180 => array('--', 't_decrement'),
		3190 => array('.=', 't_contat_equal'),
		3200 => array('/=', 't_div_equal'),
		3210 => array('*=', 't_mul_equal'),
		3220 => array('%=', 't_mod_equal'),
		3230 => array('::', 't_double_colon'),
		3240 => array('|=', 't_or_equal'),
		3250 => array('<<', 't_bin_sl'),
		3260 => array('>>', 't_bin_sr'),
		3270 => array('^=', 't_xor_equal')
	);
	foreach($joperators as $kid=>$a) $jdict[$kid] = $a[1];

	// espaco em branco nao tem palavra reservada!
	$jdict[4000] = 'j_whitespace';

	$jdict[4001] = 'j_comment';
	$jdict[4002] = 'j_encapsed_string';
	$jdict[4003] = 'j_named';
	$jdict[4004] = 'j_varname';
	$jdict[4005] = 'j_fncname';
	$jdict[4006] = 'j_number';
	$jdict[4007] = 'j_fncparam';
	$jdict[4008] = 'j_propertie';
	$jdict[4009] = 'j_resumed_string';
	$jdict[9999] = 'j_unknow';

	// declarar todas as contantes
	foreach($jdict as $kid=>$kword) define($kword, $kid);

	// ordenar por tamanho da palavra
	$tmp = array();
	$i = 0;
	foreach($jreserved as $kid=>$word){
		$i++;
		$l = strlen($word);
		// lancar grandeza
		$n = $l*1000;
		$tmp[$n+$i] = $word;
	}
	krsort($tmp);
	$swords = array_values($tmp);

	// gerar indice de palavras como chave e id como valor
	$jwords = array();
	foreach($jreserved as $kid=>$word) $jwords[$word] = $kid;

	// organizar indices da lista de tokens
	function jserialize($tokens){
		// reordenar indice
		$newtokens = array();
		$MK = 0;
		foreach($tokens as $oldk=>$token) $newtokens[$MK++] = $token;
		return($newtokens);
	}

	// funcao de tokenizer
	function jtokenizer($src){
		global $joperators;
		global $jbasics;
		global $jreserved;
		global $jreserved_ctrl;
		global $jwords;
		$debug = true;
		$debug = false;
		$len = strlen($src);
		$tokens = array();
		
		/*
			onde estou?
			0 = no codigo fonte
			1 = dentro de uma string dupla "
			2 = dentro de uma string simples '

			4 = em comentario de linha
			5 = em comentario de block
		*/
		$stat = 0;
		
		// nome de palavra definida pelo programador
		$entry = '';

		// processar byte a byte!	
		$MASTER_KEY = 0;
		for($i=0;$i<$len;$i++){
			$MASTER_KEY++;
			
			// pegar bytes
			$_P = ''; if($i) $_P = substr($src, $i-1, 1);	// anterior
			$_A = substr($src, $i, 1);						// atual
			$_N = ''; if($i<$len) $_N = substr($src, $i+1, 1);
			
			
			// analise de comentario em bloco
			if($_A == '/' && $_N == '*'){
				// inicio de comentario em bloco encontrado
				// procurar fim do bloco e coletar comentario
				$tmp = strpos($src, '*/', $i+2);
				if($tmp===false){
					// problema fatal
					die("ERRO FATAL: comentario em bloco iniciando em ".$i." nao foi finalizado.");
				}
				$tmp++; // avancar uma posicao para cobrir o /
				// coletar comentario
				$cmt = substr($src, $i, $tmp-$i+1);
				$tokens[$MASTER_KEY] = array(0=>j_comment, 1=>$cmt, 2=>$i);
				if($debug) echo "COMMENT BLOCK: [<pink>".$cmt."</pink>]\n";
				// avancar para posicao apos comentario
				$i = $tmp;
				continue;
			}

			// analise de comentario em linha
			if($_A == '/' && $_N == '/'){
				// procurar fim da linha e coletar comentario
				$tmp = strpos($src, "\n", $i+2);
				if($tmp===false){
					// problema fatal
					die("ERRO FATAL: comentario em linha iniciando em ".$i." nao foi finalizado.");
				}
				// coletar comentario
				$cmt = substr($src, $i, $tmp-$i);
				$tokens[$MASTER_KEY] = array(0=>j_comment, 1=>$cmt, 2=>$i);
				if($debug) echo "COMMENT LINE.: [<magenta>$cmt</magenta>] from $i to $tmp, ".($tmp-$i)."/".strlen($cmt)." bytes\n";

				// avancar para posicao apos comentario, mas nao pular quebra de linha
				$i = $tmp-1;
				continue;
			}
			

			// analise de string  -----------------------------------------------------------------------------
			if($_A == '"' || $_A == "'"){
				// inicio de aspas duplas
				$str = $_A;
				$markpos = $i;

				// avancar para proximo byte, posterior a abertura da string
				$i++;
				
				// iniciar busca
				$found = false;
				while(!$found && $i<$len){
					// coletar byte atual
					$instr_actual = substr($src, $i, 1);		// caracter atual
					$instr_next = substr($src, $i+1, 1);	// proximo caracter
					$str .= $instr_actual;

					// analise de escape do proximo byte, se o proximo estiver escapado, envolve-lo e seguir apos ambos
					if($instr_actual=='\\'){ $str.=$instr_next; $i+=2; continue; }

					// encontrei o mesmo byte que abriu a string, string finalizada
					if($instr_actual==$_A){
						$found = true;
						break;
					}
					$i++;
				}
				if(!$found){
					// erro, fim da string nao encontrado
					die("ERRO fatal, string iniciada em ".$markpos." nao foi finalizada com byte [".$_A."]");
				}
				
				// analisar se a aspas duplas sao necessarias
				if(substr($str, 0, 1)=='"'){
					$tmp = substr($str, 1, -1);
					if(strpos($tmp, '\\')===false && strpos($tmp, "'")===false) $str = "'".$tmp."'";
				}
				
				// string coletada com sucesso
				$tokens[$MASTER_KEY] = array(0=>j_encapsed_string, 1=>$str, 2=>$markpos);
				if($debug) echo "STRING.......: [<string>".$str."</string>]\n";
				continue;
			}


			// WHITESPACE  ---------------------------------------------------------------------------
			if($_A == ' ' || $_A == "\t" || $_A == "\n" || $_A == "\r" || $_A == "\v" || $_A == "\f"){
				// espaco em banco!
				$tokens[$MASTER_KEY] = array(0=>j_whitespace, 1=>$_A, 2=>$i);
				if($debug) echo "WHITE SPACE..: [<yellow>".ord($_A)."</yellow>]\n";
				continue;
			}

			// sequencias grandes de operadores ------------------------------------------------------
			$found = false;
			$word_len = 0;
			foreach($joperators as $x=>$a){
				$find = $a[0];
				$word_len = strlen($find);
				if(substr($src, $i, $word_len)==$find){
					// sequencia encontrada
					$tokens[$MASTER_KEY] = array(0=>$x, 1=>$find, 2=>$i);
					$found = true;
					if($debug) echo "OPP..........: [<green>$find (".$word_len.")</green>]\n";
					break;
				}
				// $i += $word_len;
			}
			// coletado, seguir adiante
			if($found){
				$i += ($word_len-1);
				continue;
			}


			// caracteres de controle de bloco ------------------------------------------------------
			$found = false;
			$word_len = 0;
			foreach($jbasics as $x=>$a){
				$find = $a[0];
				$word_len = strlen($find);
				if($_A==$find){
					// byte de controle encontrado
					$tokens[$MASTER_KEY] = array(0=>$x, 1=>$find, 2=>$i);

					if($find=='}'){
						// token adicional para evitar erro de interpretacao
						// de funcao armazenada seguida de outra:
						// stdlib.a = function(){} stdlib.b = {};
						//$tokens[++$MASTER_KEY] = array(0=>j_separator, 1=>';', 2=>$i);
					}


					$found = true;
					if($debug) echo "BASIC RSV....: [<basic>".$find."</basic>]\n";
					break;
				}
			}
			// coletado, seguir adiante
			if($found){
				$i += ($word_len-1);
				continue;
			}


			// procurar palavras reservadas, o byte posterior a analise nao pode ser a-z0-9_ pois
			// caracterizaria uso de palavra reservada como parte do nome, exemplo: functionalize tem function no nome
			// mas nao é palavra reservada
			// procurar da maior para menor para evitar de uma palavra reservada
			// ser parte de outra
			$found = 0;
			$next_byte = 0;
			$previus_byte = 0;
			$word_len = 0;
			foreach($jwords as $word=>$wid){
				// tamanho da palavra reservada
				$word_len = strlen($word);

				// pegar pedaco do fonte do tamanho da palavra reservada
				$source_part = substr($src, $i, $word_len);

				// compara pedaco do fonte com a palavra
				if($word == $source_part){
					
					
					// encontrou, previnir enganos com byte pos-palavra
					// caracter posterior a palavra
					$next_byte = ord(substr($src, $i+$word_len, 1));
					$previus_byte = ord(substr($src, $i-1, 1));

					// 65-90		A-Z
					// 97-122		a-z
					// 48-57		0-9
					// 95			_
					$found = 1;
					
					// byte anterior nao pode ser ascii
					if(
						($previus_byte <= 90 && $previus_byte >= 65) ||
						($previus_byte <= 122 && $previus_byte >= 97) ||
						($previus_byte <= 57 && $previus_byte >= 48) ||
						($previus_byte == 95)
					){
						// caracter de continuacao de palavra que nao é reservada
						$found = 0;
					}

					// byte posterior nao pode ser ascii
					if(
						($next_byte <= 90 && $next_byte >= 65) ||
						($next_byte <= 122 && $next_byte >= 97) ||
						($next_byte <= 57 && $next_byte >= 48) ||
						($next_byte == 95)
					){
						// caracter de continuacao de palavra que nao é reservada
						$found = 0;
					}
					
					// byte anterior nao pode ser ascii
					

					if($found){
						// avancar para depois da palavra
						$i += $word_len-1;
						// coletar
						$tokens[$MASTER_KEY] = array(0=>$wid, 1=>$word, 2=>$i);
						if($debug) echo "WORD RSV.....: [<reserved>".$word."</reserved>]\n";

						break;
					}
				}
			}
			//if($debug) echo "PAROU: x($wid) word[$word] txp[$source_part] la[$word_len] i[$i] pw[$next_byte] {".chr($next_byte)."}\n";
			// palavra encontrada, continuar
			if($found){
				continue;
			}
			// $jreserved
			

			// desconhecida, ler palavra ate seu fim ----------------------------------------------------------
			$tokens[$MASTER_KEY] = array(0=>j_unknow, 1=>$_A, 2=>$i);
			if($debug) echo "UNKNOW.......: [<unknow>".$_A."</unknow>]\n";
		}
		
		// reunir sequencias unknow em palavras identificadas
		foreach($tokens as $w=>$token){
			if(!isset($tokens[$w])) continue;
			
			$prev = false; if(isset($tokens[$w-1])) $next = $tokens[$w-1];
			$act = $token;
			$next = false; if(isset($tokens[$w+1])) $next = $tokens[$w+1];
			
			// sempre jogar para o proximo e por fim renomear ultimo segmento unknow
			if($act[0]==j_unknow){
				$code = $act[1];
				for($i=$w+1; $i < $MASTER_KEY; $i++){
					if(!isset($tokens[$i])) continue;
					
					// unknow encontrado
					if($tokens[$i][0] == j_unknow){
						$code .= $tokens[$i][1];
						unset($tokens[$i]);
						continue;
					}
					// nao e' unknow, parar coleta
					break;
				}
				
				// verificar se e' um numero
				if(@eregi('^[0-9]+$', $code)){
					$tokens[$w][0] = j_number;
					if($debug) echo "NUMBER.......: [<number>".$code."</number>]\n";
				}else{
					$tokens[$w][0] = j_named;
					if($debug) echo "NAMED WORD...: [<named>".$code."</named>]\n";
				}
				$tokens[$w][1] = $code;
				continue;
			}
		}
		
		// reordenar indice
		$newtokens = array();
		$MASTER_KEY = 0;
		foreach($tokens as $oldk=>$token){
			$MASTER_KEY++;
			$newtokens[$MASTER_KEY] = $token;
		}
		$tokens = $newtokens;
		
		// identificar variaveis declaradas com comando 'var'
		foreach($tokens as $k=>$token){
			
			// identificar token anterior
			$prev = array(0, ''); $PREV = -1;
			$x = $k-1;
			while($x >= 0){ if(isset($tokens[$x])){ $prev = $tokens[$x]; $PREV = $x; break; } $x--; }
			
			// atual
			$ACT = $k;
			$act = $token;
			
			// identifica proximo
			$next = array(0, ''); $NEXT = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){ if(isset($tokens[$x])){ $next = $tokens[$x]; $NEXT = $x; break; } $x++; }

			// identifica proximo que nao seja espaco ou comentario
			$prox = array(0, ''); $PROX = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){
				if(isset($tokens[$x]) && $tokens[$x][0] != j_whitespace && $tokens[$x][0] != j_comment){
					$prox = $tokens[$x];
					$PROX = $x;
					break;
				}
				$x++;
			}

			
			// ----------------- j_var
			if($act[0] == j_var && $prox[0] == j_named){
				$tokens[$PROX][0] = $prox[0] = j_varname;
			}

			// ----------------- j_fncname
			if($act[0] == j_function && $prox[0] == j_named){
				$tokens[$PROX][0] = $prox[0] = j_fncname;
			}

		}
		
		// marcar como j_varname as palavras tipo j_named que estiverem dentro do mesmo escopo de j_varname
		$max = count($tokens);

		foreach($tokens as $k=>$token){
			if($token[0] == j_varname){
				$varname = $token[1];
				$locidx = $k;
				// - iniciar busca por j_named dentro do mesmo escopo
				$level = 1;
				
				// percorrer token a token ate fim do nivel atual
				$cc = -1;
				$last = array(0=>'', 1=>0);
				while($cc++ < $max && ($level >= 1 || $locidx > $MASTER_KEY)){

					// mover para proximo token
					$locidx++;
					
					if(!isset($tokens[$locidx])) break;
					
					$_token = $tokens[$locidx];
					
					// abertura de bloco encontrada
					if($_token[0] == j_open_block){ $level++; continue; }
					// fechamento de bloco encontrada
					if($_token[0] == j_close_block){ $level--; continue; }
					
					// token no meio do contexto
					if($varname == $_token[1] && $last[1]!='.'){
						$tokens[$locidx][0] = j_varname;
						$last = $_token;
						continue;
					}
					$last = $_token;
				}
			}
		}
		
		// CORRECOES - bug de bloco fechando na mesma linha de inicio de outra instrucao sem separador
		$K = 0;
		$fixed = array();
		foreach($tokens as $k=>$token){
			// identificar token anterior
			$prev = array(0, ''); $PREV = -1;
			$x = $k-1;
			while($x >= 0){ if(isset($tokens[$x])){ $prev = $tokens[$x]; $PREV = $x; break; } $x--; }
			
			// atual
			$ACT = $k;
			$act = $token;
			
			// identifica proximo
			$next = array(0, ''); $NEXT = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){ if(isset($tokens[$x])){ $next = $tokens[$x]; $NEXT = $x; break; } $x++; }

			// identifica proximo que nao seja espaco ou comentario
			$prox = array(0, ''); $PROX = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){
				if(isset($tokens[$x]) && $tokens[$x][0] != j_whitespace && $tokens[$x][0] != j_comment){
					$prox = $tokens[$x]; $PROX = $x; break;
				}
				$x++;
			}

			// inserir separador entre fechamento de bloco e nova entidade
			if($token[0]==j_close_block && (
				$prox[0]==j_named || $prox[0] == j_fncname || $prox[0] == j_varname
			)){
				$fixed[++$K] = $token;
				$fixed[++$K] = array(j_separator, ";", -1);

			//}elseif($token[0]==j_separator){
			//	$token[1] = ";";
			//	$fixed[++$K] = $token;
			}else{
				$fixed[++$K] = $token;
			}
		}
		$tokens = $fixed;
		$MASTER_KEY = $K;
		
		// definir propriedade j_dot j_propertie
		foreach($tokens as $k=>$token){
			if($token[0]==j_dot && $tokens[$k+1][0]==j_named) $tokens[$k+1][0]=j_propertie;
		}
	
		// identificar variaveis usadas como parametros de funcoes
		foreach($tokens as $k=>$token){
			
			// j_fncparam
			if($token[0]==j_function){
				
				// mapa local de funcoes
				$function_map = array();
				$function_tokens = array();
				
				// procurar abertura de parametros
				$m = $k-1;
				$param_open = 0;
				$param_readed = 0;
				$param_count = 0;
				$param_list = array();
				
				$function_tokens[$m] = $token;
				while($m++ <= $MASTER_KEY){
					if(!isset($tokens[$m])) continue;
					$_token = $tokens[$m];

					// copiar para escopo da funcao
					$function_tokens[$m] = $_token;
					
					// esquisito....
					if($_token[1]=='|' && !$param_open && !$param_readed) break;
					
					if($_token[1]=='(' && !$param_open && !$param_readed){
						$param_open = 1;
					}
					if($_token[1]==')' && $param_open){
						$param_open = 0;
						$param_readed = 1;
						break;
					}
					
					// leitura de parametros
					if(!$param_readed && $param_open){
						if($_token[0] == j_named){
							$tokens[$m][0] = $_token[0] = j_fncparam;
							$_vn = $_token[1];
							$param_list[] = $_vn;

							if(!isset($function_map[$_vn])) $function_map[$_vn] = jgetname($_vn, count($function_map));
							//echo "PARAM FUNCTION: ".$_vn." == ".$function_map[$_vn]."<br>";

							// copiar para escopo da funcao
							$function_tokens[$m] = $_token;

							//$n = $_token[1];
							//if(!isset($function_map[$n])) $function_map[$n] = jgetname($n, count($function_map));
							//$tokens[$m][0] = $_token[1] = $function_map[$n];

							$param_count++;
						}
					}
				
				}
			
				// leitura de parametros concluida, iniciar
				// leitura de bloco
				//if($param_readed && $param_count && $m <= $MASTER_KEY){
				if($m <= $MASTER_KEY){
					$level = 0;
					while($m <= $MASTER_KEY){
						if(!isset($tokens[$m])){
							$m++;
							continue;
						}
						$_token = $tokens[$m];
						$function_tokens[$m] = $_token;
						
						// novo level (a funcao ou algum bloco dentro dela)
						if($_token[1] == '{'){
							$level++;
							$m++;
							continue;
						}
						
						// fim da funcao
						if($_token[1] == '}'){
							$level--;
							if(!$level) break;
							$m++;
							continue;
						}
						
						// analisar entidade
						if($_token[0] == j_named && in_array($_token[1], $param_list)){
							$tokens[$m][0] = $_token[0] = j_fncparam;

							//echo "VARIAVEL NOMEADA NA FUNCAO: ".$_token[1]."\n";

							// copiar para escopo da funcao
							$function_tokens[$m] = $_token;

						}
						$m++;
					}
				}

				// reescrever nome de variaveis do escopo
				if(1) foreach($function_tokens as $idx=>$ftoken){
					// nome de variavel/parametro
					$_vn = $ftoken[1];
					
					// codificar variavel local
					if($ftoken[0] == j_varname && !isset($function_map[$_vn])){
						$function_map[$_vn] = jgetname($_vn, count($function_map));
					}
					
					if($ftoken[0]==j_fncparam || $ftoken[0] == j_varname){

						if(isset($function_map[$_vn])){
							$_vnf = $function_map[$_vn];
							$tokens[$idx][7] = $function_tokens[$idx][7] = $_vnf;
						}
					}
				}
				// DEBUG
				/*
				echo '<pre>Escopo da funcao:<hr>'."\n";
				foreach($function_tokens as $_0=>$_1){
					if($_1[0]==j_fncparam) echo '<j_fncparam>';
					if($_1[0]==j_varname) echo '<j_varname>';
					
					echo $_1[1];
					if($_1[0]==j_fncparam) echo '</j_fncparam>';
					if($_1[0]==j_varname) echo '</j_varname>';

				}
				echo "\n\n";
				print_r($function_map);
				echo "\n";
				echo '<hr></pre>';
				*/

			} // if function
		}
		return($tokens);
	}

	// converter tokens em codigo-fonte
	function jimplode($tokens){
		$joined = '';
		foreach($tokens as $k=>$token)$joined .= $token[1];
		return($joined);
	}

// ------------------------------------------- FUNCOES DE OPTIMIZACAO --------------------------------------------------

	// array para traducao de palavra=>WORDCODE
	$jtranslate = array();


	// recebe lista de tokens e retorna nova lista optimizada
	function joptimize($tokens){
		global $joperators;
		global $jbasics;
		global $jreserved;
		global $jreserved_ctrl;
		global $jwords;
		global $jtranslate;
	
		// interpretar string direta
		if(is_string($tokens)) $tokens = jtokenizer($tokens);
	
	
		// serializar lista
		$tokens = jserialize($tokens);
		$MASTER_KEY = count($tokens);
		$c = 0;
		for($A=0;$A<2;$A++) foreach($tokens as $k=>$token){
			if(!isset($tokens[$k])) continue;
			$c++;

			// identificar token anterior
			$prev = array(0, ''); $PREV = -1;
			$x = $k-1;
			while($x >= 0){ if(isset($tokens[$x])){ $prev = $tokens[$x]; $PREV = $x; break; } $x--; }
			
			// atual
			$ACT = $k;
			$act = $token;
			
			// identifica proximo
			$next = array(0, ''); $NEXT = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){ if(isset($tokens[$x])){ $next = $tokens[$x]; $NEXT = $x; break; } $x++; }

			// identifica proximo que nao seja espaco ou comentario
			$prox = array(0, ''); $PROX = -1;
			$x = $k+1;
			while($x <= $MASTER_KEY){
				if(isset($tokens[$x]) && $tokens[$x][0] != j_whitespace && $tokens[$x][0] != j_comment){
					$prox = $tokens[$x]; $PROX = $x; break;
				}
				$x++;
			}
	
			// token e byte atual anterior
			$prev_token = $prev[0];
			$prev_code = $prev[1];

			// token e byte atual
			$act_token = $act[0];
			$act_code = $act[1];

			// proximo token e byte		
			$next_token = $next[0];
			$next_code = $next[1];

			// proximo token e byte		
			$prox_token = $prox[0];
			$prox_code = $prox[1];
			
			// sequencia de tres codigos
			$seq = $prev_code . $act_code . $next_code;
			$pseq = $prev_code . $act_code;
			$nseq = $act_code . $next_code;

			
			// PROCESSAR TOKEN A TOKEN
			$rm_act = 0;
			$rm_nxt = 0;
			$rm_prv = 0;
			$rm_prx = 0;
		
			// remover comentarios transformando-os em brancos
			if($act_token==j_comment){ $rm_act = 1; }

			// limpezas de remocao do separador ';'
			// ;else
			if($act_token==j_separator){

				// duplo separador
				if($next_token == j_separator) $rm_act = 1120;
				
				// espaco apos separador
				//if($next_token == j_whitespace) $rm_act = 1121;

				// quando o proximo for um comando de controle basico ELSE
				//if(!$rm_act && $next_code == 'else') $rm_act = 1122;
				
				// bug - ;, - ponto-e-virgula e virgula
				if(!$rm_act && $next_code == ',') $rm_act = 1123;
				
				
				// bug - );}
				if(!$rm_act && $seq == ');}') $rm_act = 1124;
				if(!$rm_act && $seq == '};}') $rm_act = 1125;
				if(!$rm_act && $seq == '};catch') $rm_act = 1126;
				if(!$rm_act && $seq == 'continue;}') $rm_act = 1127;
				
				// espaco desnecessario
				if(!$rm_nxt && $next_token == j_whitespace && ($prox_token == j_named || $prox_token == j_varname)){
					$rm_nxt = 19;
				}
				
			}

			// remover virgula antes do fechamento de objetos, causa problema no IE
			if($act_token==j_virg && $next[0]==j_close_block) $rm_act = 777;

			// remover espacos duplos
			if($act_token==j_whitespace && $prev[0]==j_whitespace) $rm_act = 2;
		
		
			// espacos ANTES ou DEPOIS de tokens basicos
			
			if($act_token==j_whitespace){
				$tmp = 2000;
				foreach($jbasics as $kb=>$jb){
					$tmp++; if($jb[0] == $next[1] || $jb[0] == $prev[1]){$rm_act = $tmp; break; }
				}
			}

			// espacos ANTES ou DEPOIS de tokens operadoras
			if($act_token==j_whitespace){
				$tmp = 3000;
				foreach($joperators as $kb=>$jb){
					$tmp++; if($jb[0] == $next[1] || $jb[0] == $prev[1]){$rm_act = $tmp; break; }
				}
			}
					
			//echo "CHECK prev (".$prev[1]." $rm_prv) act (".$act[1]." $rm_act)  next(".$next[1]." $rm_nxt)\n";

			// EXECUTAR REMOCAO
			if($rm_prv && isset($tokens[$PREV])) unset($tokens[$PREV]);
			if($rm_nxt && isset($tokens[$NEXT])) unset($tokens[$NEXT]);
			if($rm_prx && isset($tokens[$PROX])) unset($tokens[$PROX]);
			if($rm_act && isset($tokens[$ACT])) unset($tokens[$ACT]);
			
		}
		
		// optimizacoes secundarias

		// TRIM de j_whitespace
		
		
		// reducao de nome de variaveis locais
		foreach($tokens as $k=>$token){
			if(!isset($tokens[$k])) continue;
			
			//echo "PROCESS: ".$token[0]." = (".$token[1].")\n";
			
			// variaveis declaradas
		//	if($token[0] == j_varname && strlen($token[1]) >= 3){
			if($token[0] == j_varname){
			//if($token[0] == j_varname){
				$n = $token[1];
				if(!isset($jtranslate[$n])) $jtranslate[$n] = jgetname($n, count($jtranslate));
				$tokens[$k][1] = $token[1] = $jtranslate[$n];
			}

			// parametros de funcoes
			//if($token[0] == j_fncparam && strlen($token[1]) >= 3){
			if($token[0] == j_fncparam){
				$n = $token[1];
				if(!isset($jtranslate[$n])) $jtranslate[$n] = jgetname($n, count($jtranslate));
				$tokens[$k][1] = $token[1] = $jtranslate[$n];
			}
		}

		// codficar nomes preparados
		foreach($tokens as $k=>$v){
			if(isset($v[7])) $tokens[$k][1] = $tokens[$k][7];
		}
		
		// remocao de parenteses no typeof
		foreach($tokens as $k=>$v){
					
			if($v[0]==j_typeof){
				$c = 0;
				$x = $k+1;
				$found = 0;
				$level = 0;
				$delete = 0;
				while($c++ < 14){
					if(!isset($tokens[$x])){ $x++; continue; }
					
					// proximo token encontrado
					$t = $tokens[$x];
					if($t[1]!='(') break;
					$level++;
					$delete = $x;
					//echo "PARAM INI IN ".$x."<br>";
					
					$x++;
					// encontrado, percorrer levels e concluir
					while($c++ < 15){
						if(!isset($tokens[$x])){ $x++; continue; }
						
						// token proximo encontrado
						$t = $tokens[$x];
						$t[6] = $x;
						
						// novo level
						if($t[1]=='('){ $level++; $x++; continue; }
						
						// fim de level
						if($t[1]==')'){ $level--; }
						
						if(!$level){
							// parenteses final encontrado
							//echo "PARAM END IN ".$x." from ".$delete."<br>";
							if($delete){
								// trocar abertura por espaco
								$tokens[$delete][0] = j_whitespace;
								$tokens[$delete][1] = ' ';
								
								// remover fechamento
								unset($tokens[$x]);
							}
							break;
						}
						$x++;
					}
				}
			}
		}
		return($tokens);
	}

	function jlen($tokens){
		$c = 0;
		foreach($tokens as $k=>$token) $c+=strlen($token[1]);
		return($c);
	}

//----------------------------------------------------------------------

	// processar argumento
	if(isset($argv[0])) unset($argv[0]); // remover argumento zero
	foreach($argv as $k=>$arg){
		if(!isset($argv[$k])) continue;

		if($arg=='-h' || $arg == '-help' || $arg == '--help') _help();

		$next = isset($argv[$k+1]) ? $argv[$k+1] : '';

		// ativar debug
		if($arg=='-d'||$arg=='-debug'||$arg=='--debug'){ $DEBUG++; unset($argv[$k]); continue; }

		// terminar com quebra de linha
		if($arg=='-B'||$arg=='-newline'||$arg=='--newline'){ $INSERT_FINAL_BREAK++; unset($argv[$k]); continue; }

		// Arquivo de entrada
		if($arg=='-f' && $next != ''){
			$INPUT_FILE = $next;
			unset($argv[$k]); unset($argv[$k+1]); continue;
		}

		// Arquivo de saida
		if($arg=='-w' && $next != ''){
			$OUTPUT_FILE = $next;
			unset($argv[$k]); unset($argv[$k+1]); continue;
		}

		// Alterar INLINE
		if($arg=='-i' || $arg=='-inline' || $arg=='--inline'){ $INLINE = 1; unset($argv[$k]); continue; }

		// Argumento desconhecido:
		// 1 - se for arquivo existente, e' nosso script
		if($INPUT_FILE =='' && is_file($arg)){ $INPUT_FILE = $arg; continue; }
		if($OUTPUT_FILE==''){ $OUTPUT_FILE = $arg; continue; }
	}
	// Inline
	if($INLINE) $OUTPUT_FILE = $INPUT_FILE;

// Debug
	if($DEBUG){
		echo "[debug] INPUT FILE.: [$INPUT_FILE]\n";
		echo "[debug] OUT FILE...: [$OUTPUT_FILE]\n";
		echo "[debug] DEBUG LEVEL: [$DEBUG]\n";
	}

// Criticas
	if($INPUT_FILE==''){ _abort("Arquivo [$INPUT_FILE] nao informado.", 10); }
	if(!file_exists($INPUT_FILE)){ _abort("Arquivo [$INPUT_FILE] nao encontrado.", 11); }


// Obter conteudo do arquivo
	$file_content = file_get_contents($INPUT_FILE);
	$file_inilen = strlen($file_content); // tamanho inicial
	$file_ecolen = 0; // economia
	if($DEBUG){   echo "[debug] Tamanho do arquivo: ",$file_inilen,"\n"; }
	if($DEBUG>2){ echo "[debug] Conteudo inicial:","\n",$file_content,"\n"; }

// Converter em tokens JavaScript
	$jtokens = joptimize($file_content);
	if($DEBUG>2){ echo "[debug] Tokens:","\n";print_r($jtokens);echo "\n"; }


// Fazer limpeza de tokens inuteis
	$inilen = strlen($file_content);
	if($DEBUG){ echo "[debug] Source-Code CLEANER: JavaScript, ini-len: ",$inilen," bytes\n"; }
	$file_content = jimplode($jtokens); unset($jtokens);
	$endlen = strlen($file_content);
	$file_ecolen += ($inilen - $endlen);
	if($DEBUG){ echo "[debug] Source-Code CLEANER: JavaScript, end-len: ",$endlen," bytes\n"; }


// Inserir quebra de linha apos conteudo
	if($INSERT_FINAL_BREAK){
		$inilen = strlen($file_content);
		if($DEBUG){ echo "[debug] Pre-limpeza: INSERT-BREAK, ini-len: ",$inilen," bytes\n"; }
		$file_content .= str_repeat("\n", $INSERT_FINAL_BREAK);
		$endlen = strlen($file_content);
		$file_ecolen += ($inilen - $endlen);
		if($DEBUG){ echo "[debug] Pre-limpeza: INSERT-BREAK, end-len: ",$endlen," bytes\n"; }

	}

// Resultado
	$file_endlen = strlen($file_content); // tamanho final
	if($DEBUG){ echo "[debug] FINALIZADO. Tamanho inicial....: ",$file_inilen," bytes\n"; }
	if($DEBUG){ echo "[debug] FINALIZADO. Tamanho final......: ",$file_endlen," bytes\n"; }
	if($DEBUG){ echo "[debug] FINALIZADO. Economia total.....: ",$file_ecolen," bytes\n"; }
	if($OUTPUT_FILE!=''){
		// gravar no arquivo de saida
		if($DEBUG){ echo "[debug] GRAVANDO NO ARQUIVO: ",$OUTPUT_FILE,"\n"; }
		file_put_contents($OUTPUT_FILE, $file_content);
	}else{
		if($DEBUG){ echo "[debug] GRAVANDO NA SAIDA.","\n"; }
		echo $file_content,"\n";
	}















?>