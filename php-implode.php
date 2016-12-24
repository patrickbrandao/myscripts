#!/usr/bin/php -q
<?php

	// Versao do software
	// Usado como cache de cache
	$PHPI_VERSION = '161224-0036';

	// funcoes para transformar codigo PHP em tokens
	// DEFINICAO DE TOKENS NAO RECONHECIDOS

	// Lista de arquivos incluidos
	$PHPI_INCLUDES = array();

	// IDs e CONTANTES
	$phpt_token_list = array(
		8000 => 'T_CODE_START',
		8001 => 'T_CODE_END',
		8010 => 'T_OB_VARIABLE',
		8012 => 'T_OB_FUNCTION',
		8014 => 'T_PHPOB_FUNCTION',
		
		8020 => 'T_CONSTANT',

		8030 => 'T_OB_STRING_B64E',
		8031 => 'T_OB_STRING_B64R',
		8032 => 'T_OB_STRING_HEXE',

		8040 => 'T_OB_HTML',

		8999 => 'T_UNKNOW_STRING',

		9001 => 'T_PURE',
		9002 => 'T_EQUAL',
		9003 => 'T_SEPARATOR',
		9004 => 'T_ASPAS',
		9005 => 'T_OPEN_BLOCK',
		9006 => 'T_CLOSE_BLOCK',
		9007 => 'T_OPEN_PARAM',
		9008 => 'T_CLOSE_PARAM',
		9009 => 'T_VIRG',
		9010 => 'T_DOT',
		9011 => 'T_PHP_FUNCTION',		// requer analise de T_STRING na lista de funcoes nativas do php
		9012 => 'T_CLASS_NAME',			// nome de classe
		9013 => 'T_FUNCTION_NAME',		// nome de funcao
		9014 => 'T_STATIC_PHP_HTML',	// html estatico convertido para php
		9015 => 'T_OPEN_KEY',
		9016 => 'T_CLOSE_KEY',
		9017 => 'T_ECOM',
		9018 => 'T_BOOL_INVERT',
		9019 => 'T_MAGIC_ALL',
		9020 => 'T_SIGNAL_MINUS',
		9021 => 'T_OPEN_XMLTAG',
		9022 => 'T_CLOSE_XMLTAG',
		9023 => 'T_QUESTION',
		9024 => 'T_DOUBLE_DOT',
		9025 => 'T_SIGNAL_PLUS',
		9026 => 'T_SIGNAL_REST',
		9027 => 'T_SIGNAL_ELEV',
		9028 => 'T_ARROBA',
		9029 => 'T_SIGNAL_DIV',
		9030 => 'T_BIT_OP_AND',
		9031 => 'T_BIT_OP_OR',
		9032 => 'T_CLASS_MEMBER',
		9033 => 'T_X_SPACESHIP',
		9998 => 'T_SEP_ECHO',
		9999 => 'T_EXPLICIT'
	);
	// IDs e codigo php
	$phpt_token_sets = array(
		9002 => '=',
		9003 => ';',
		9004 => '"',
		9005 => '{',
		9006 => '}',
		9007 => '(',
		9008 => ')',
		9009 => ',',
		9010 => '.',
		
		9015 => '[',
		9016 => ']',
		9017 => '&',
		9018 => '!',
		9019 => '*',
		9020 => '-',
		9021 => '<',
		9022 => '>',
		9023 => '?',
		9024 => ':',
		9025 => '+',
		9026 => '%',
		9027 => '^',
		9028 => '@',
		9029 => '/',
		9030 => '~',
		9031 => '|',
		9033 => '<=>'
	);
	foreach($phpt_token_list as $t_id=>$t_name) define($t_name,  $t_id);

	// chaves do phpt_token_get_all
	define('TOKEN_CODE', 0);
	define('TOKEN_CONTENT', 1);
	define('TOKEN_LINE', 2);
	define('TOKEN_NAME', 3);
	define('TOKEN_FQDN', 4);

	// tokens especiais
	define('TOKEN_INLINE_LIST', 189000); // o token é uma lista de tokens
	define('T_HTML_TO_PHP', 189001); // o token é um html convertido em: echo base64_decode('xxxx');
	define('T_CACHE_TAIL', 189002); // token vazio, sinalizador de tokens obtidos no cache

	// sinalizacoes
	define('TOKEN_PREV', 3);
	define('TOKEN_ACT', 4);
	define('TOKEN_NEXT', 5);
	define('TOKEN_FIX', 6);
	define('TOKEN_DEL', 7);

	// identificar nome do token pelo ID
	function php_token($tid){
		global $phpt_token_list;
		foreach($phpt_token_list as $t_id=>$t_name) if($t_id==$tid) return($t_name);
		return token_name($tid);
	}
	// obter id do token nao mapeado pelo caracter/texto
	function php_strcode($str){
		global $phpt_token_sets; $tid = T_PURE;
		foreach($phpt_token_sets as $t_id=>$t_str){
			if($str==$t_str){ $tid = $t_id; break; }
		}
		return $tid;
	}

	// Limpar tokens desnecessarios
	function _php_clean(&$tokens){
		// array com lista de elementos que nao precisam
		// ter outros espacos antes ou depois
		$no_whitespace_borders = array(
			T_WHITESPACE,
			T_EQUAL, T_VARIABLE,
			T_IF, T_WHILE, T_SEPARATOR,
			T_IS_EQUAL, T_IS_GREATER_OR_EQUAL, T_IS_IDENTICAL, T_IS_NOT_EQUAL,
			T_IS_NOT_IDENTICAL, T_IS_SMALLER_OR_EQUAL, T_X_SPACESHIP, T_XOR_EQUAL,
			T_OBJECT_OPERATOR, T_NS_SEPARATOR, T_MUL_EQUAL, T_MOD_EQUAL, T_MINUS_EQUAL, 
			T_DIV_EQUAL, T_CONCAT_EQUAL, T_BOOLEAN_OR, T_BOOLEAN_AND, T_AND_EQUAL, 
			T_INC, T_DEC, 
			T_CONSTANT_ENCAPSED_STRING,
			T_FOR, T_FOREACH, T_ENCAPSED_AND_WHITESPACE, T_DOUBLE_ARROW,
			T_OR_EQUAL, T_PAAMAYIM_NEKUDOTAYIM, T_PLUS_EQUAL, T_POW, T_POW_EQUAL,
			T_SL, T_SL_EQUAL, T_SR, T_SR_EQUAL, T_START_HEREDOC,
			T_STRING_CAST, T_SWITCH, T_THROW, T_TRY,
			T_VIRG, T_DOUBLE_DOT,
			T_OPEN_PARAM, T_CLOSE_PARAM,
			T_OPEN_BLOCK, T_CLOSE_BLOCK,
			T_HTML_TO_PHP,
			T_ECOM
		);
		for($job=0; $job < 3; $job++){
			foreach($tokens as $k=>$token){
				if(!isset($tokens[$k])) continue;
				// token atual
				$act_token = $tokens[$k][TOKEN_CODE]; // codigo do token atual
				$act_id = $k;
				// proximo token +1
				$nxt_token = 0;
				$nxt_id = -1;
				for($i=1; $i < 3; $i++)
					if(isset($tokens[$k+$i])){ $nxt_token = $tokens[$k+$i][TOKEN_CODE]; $nxt_id = $k+$i; break; }
				//-
				// primeiro token e' espaco, ciao
				if($act_token===T_WHITESPACE && $k === 0){ unset($tokens[$k]); continue; }
				// XXXX + espaco = XXXX
				if(in_array($act_token, $no_whitespace_borders) && $nxt_token===T_WHITESPACE){ unset($tokens[$k+1]); continue; }
				// espaco + XXXX = XXXX
				if($act_token===T_WHITESPACE && in_array($nxt_token, $no_whitespace_borders)){ unset($tokens[$k]); continue; }
			}
			// serializar
			$ntokens = array(); $c = 0;
			foreach($tokens as $k=>$token) $ntokens[$c++] = $token;
			$tokens = $ntokens; unset($ntokens);
		}
	}

	// converter HTML em tokens PHP
	function _php_convert_html(&$tokens){
		$c = 0;
		foreach($tokens as $k=>$token){
			if(!isset($tokens[$k])) continue;
			$c++;
			// codigo do token atual
			$act_token = $tokens[$k][TOKEN_CODE]; $act_id = $k;
			// ignorar token nao-HTML
			if($act_token!=T_INLINE_HTML) continue;
			// proximo token
			$nxt_token = 0; $nxt_id = -1;
			if(isset($tokens[$k+1])){ $nxt_id = $k+1; $nxt_token = $tokens[$nxt_id][TOKEN_CODE]; }
			// primeiro token HTML pode ser na verdade
			// o comando do interpretador, #!/....
			if($c===1){
				$xstr = trim($tokens[$act_id][TOKEN_CONTENT]);
				// token do interpretador, ignorar conversao
				if(substr($xstr, 0, 3) == '#!/') continue;
			}
			// pode acontecer de a limpeza retirar espacos entre dois
			// tokens HTML, converter tokens HTML seguidos em um unico
			// token concatenado
			if($act_token===T_INLINE_HTML && $nxt_token===T_INLINE_HTML){
				// concatenar tokens
				$tokens[$act_id][TOKEN_CONTENT] = $tokens[$act_id][TOKEN_CONTENT] . $tokens[$nxt_id][TOKEN_CONTENT];
				// remover proximo token
				unset($tokens[$nxt_id]); $nxt_id = -1;
			}
			// transformar token HTML em token especial concatenado
			$tokens[$act_id][TOKEN_CODE] = T_HTML_TO_PHP;
			$tokens[$act_id][TOKEN_NAME] = 'T_HTML_TO_PHP';
			$tokens[$act_id][TOKEN_CONTENT] = "echo base64_decode('".base64_encode($tokens[$act_id][TOKEN_CONTENT])."');";
		}
	}

	// executar tokenizer completo
	/*
	Array de tokens:
		array(
			token_id => array(
				0 => numero codigo do token,
				1 => string do token,
				2 => numero da linha
				3 => nome do token (string)
			)
		)
	*/
	// remover todos os T_OPEN_TAG e T_CLOSE_TAG
	// iremos usar a vizinhanca com o token T_INLINE_HTML
	// para reinserir esses tokens apos implodir codigos
	// cujo inicio e fim sao desconhecidos (seja php abertura ou fechamento, ou html)
	function php_tokenizer($source, $phpfile){
		global $phpt_token_sets;
		$tokens = token_get_all($source);
		// 1 - identificar partes brutas nao reconhecidas
		$lastlinenum = 0;
		foreach($tokens as $k=>$part){
			if(is_array($part)){
				// remover abertura e fechamento de codigo PHP
				if($part[TOKEN_CODE]===T_OPEN_TAG || $part[TOKEN_CODE]===T_CLOSE_TAG){
					unset($tokens[$k]);
					continue;
				}
				// preencher o nome do token
				$tokens[$k][TOKEN_NAME] = php_token($tokens[$k][TOKEN_CODE]);
				$tokens[$k][TOKEN_FQDN] = $phpfile;
				$lastlinenum = $tokens[$k][TOKEN_LINE];
			}else{
				// identicar token
				$tid = php_strcode($part);
				$tokens[$k] = array(
					TOKEN_CODE => $tid,
					TOKEN_CONTENT => $part,
					TOKEN_LINE => $lastlinenum,
					TOKEN_NAME => php_token($tid),
					TOKEN_FQDN => $phpfile
				);
			}
		}
		return $tokens;
	}

	// tokenizar arquivo
	function php_tokenizer_file($phpfile){
		global $CACHE_ENABLE;
		global $CACHEDIR;
		global $CACHEPREFIX;
		global $ENABLE_DEBUG;
		global $PHPSTRIPCLEAN;
		global $IMPLODE_REQUIRE;
		global $PHPIZE_HTML;
		// Obter caminho completo para o script
		if(!is_file($phpfile)) return array();
		// Consultar cache
		$cachetokfile = ''; $cachemd5file = ''; $md5file = ''; $incache = 0;
		// construir cache de cache com opcoes
		// $cachekey =  ($PHPSTRIPCLEAN?'strip':'no-strip') .  ($PHPIZE_HTML?'html2php':'html2php') .  ($IMPLODE_REQUIRE?'reqimplode':'no-reqimplode');
		if($CACHE_ENABLE){
			$cachetokfile = $CACHEDIR . '/' . $CACHEPREFIX . '-' . str_replace('/', '-', $phpfile) . '.phpi';
			$cachemd5file = $CACHEDIR . '/' . $CACHEPREFIX . '-' . str_replace('/', '-', $phpfile) . '.md5';
			if(is_file($cachetokfile) && is_file($cachemd5file)){
				$md5cache = trim(file_get_contents($cachemd5file));
				$md5file = md5_file($phpfile);
				if($md5cache === $md5file)
					// esta em cache, retornar tokens pre-compilados
					return unserialize(file_get_contents($cachetokfile));
				//-
			} // else - nao estava no cache
		} // else - cache desativado
		// obter codigo fonte do arquivo
		if($PHPSTRIPCLEAN){
			$source_code = php_strip_whitespace($phpfile);
		}else{
		 	$source_code = file_get_contents($phpfile);
		}
		// limpeza preliminar do codigo fonte
		// converter fonte em tokens PHP
		$tokens = php_tokenizer($source_code, $phpfile);
		// converter tokens HTML em PHP
		if($PHPIZE_HTML) _php_convert_html($tokens);
		// proceder com limpezas locais
		_php_clean($tokens);
		// salvar em cache
		if($CACHE_ENABLE){
			// token sinalizador de cache
			$tokens[] = array( TOKEN_CODE => T_CACHE_TAIL, TOKEN_CONTENT => '', TOKEN_LINE => @time(), TOKEN_NAME => 'T_CACHE_TAIL', TOKEN_FQDN => $phpfile );
			// obter assinatura atual do arquivo fonte
			if($md5file=='') $md5file = md5_file($phpfile);
			// gravar md5 no arquivo de assinatura do cache
			file_put_contents($cachemd5file, $md5file);
			// gravar cache
			file_put_contents($cachetokfile, serialize($tokens));
		}
		// retorno
		return $tokens;
	}

// Funcao para implodir script
	// Retorna array de tokens do script e todas as suas inclusoes via REQUIRE
	$reclevel = 0;
	function _php_implode($in_phpfile, $curpwd){
		global $PHPI_INCLUDES;
		global $reclevel;
		global $ENABLE_DEBUG;
		global $IMPLODE_REQUIRE;

		// Obter caminho completo para o script
		$phpfile = _full_file($in_phpfile);

		// Obter informacoes
		$pi = pathinfo($phpfile);
		$fname = $pi['basename'];
		$dname = $pi['dirname'];
		if($dname=='.') $dname = $curpwd;
		$sfqdn = $dname.'/'.$fname;

		if($curpwd=='') $curpwd = $dname;

		$linenum = 0;

		if($ENABLE_DEBUG){
			echo "_php_implode($in_phpfile, $curpwd)\n";
			echo "\tscript name......: [$sfqdn]\n";
			echo "\tfile name........: [$fname]\n";
			echo "\tdir name.........: [$dname]\n";
			echo "\tcur pwd..........: [$curpwd]\n";
			echo "\n";
		}

		// entrar no diretorio para procurar includes relativas
		if(is_dir($dname)) @chdir($dname);

		$PHPI_INCLUDES[$sfqdn] = isset($PHPI_INCLUDES[$sfqdn]) ? $PHPI_INCLUDES[$sfqdn]+1 : 1;
		if($PHPI_INCLUDES[$sfqdn] > 2){
			if($ENABLE_DEBUG) echo "-> Erro, inclusoes em loop do arquivo [$sfqdn]\n";
			exit(4);
		}

		// converter fonte em tokens PHP
		$tokens = php_tokenizer_file($phpfile);
		
		// se nao houver implosao de require, nao precisamos processar
		// tokens, basta retornar-los
		if(!$IMPLODE_REQUIRE) return $tokens;

		// limpar tipos whitespace afrente do require e antes do ';' posterior
		// - falta fazer, vai bugar se o programador deixar espaco apos o parenteses

		// percorrer tokens a busca de require
		$skip_tid = -1;
		foreach($tokens as $tid=>$token){
			// token deletado
			if(!isset($tokens[$tid])) continue;
			// pular tokens que nao devem ser processados
			if($tid <= $skip_tid) continue;

			// procurar sequencia:
			// T_REQUIRE + T_OPEN_PARAM + T_CONSTANT_ENCAPSED_STRING + T_CLOSE_PARAM
			if($IMPLODE_REQUIRE === 1){
				if(
					$tokens[$tid][0] === T_REQUIRE &&
					$tokens[$tid+1][0] === T_OPEN_PARAM &&
					$tokens[$tid+2][0] === T_CONSTANT_ENCAPSED_STRING &&
					$tokens[$tid+3][0] === T_CLOSE_PARAM &&
					$tokens[$tid+4][0] === T_SEPARATOR
				){
					// achou require

					// pular tokens na analise posterior
					$skip_tid = $tid + 4;

					// verificar se o alvo existe
					$inc_file = trim($tokens[$tid+2][1], " '\n\t\r".'"');

					// ingnorar includes com variaveis, elas nao podem
					// ser implodicas e funcionam se existirem em php-script
					// (PERIGO DE BUG se o alvo estiver criptografado tambem)
					if(strpos($inc_file, '$')!==false) continue;

					// obter caminho completo do fonte
					$ifile = _full_file($inc_file);
					if(!is_file($ifile) && is_file($inc_file)) $ifile = $inc_file;

					if($ENABLE_DEBUG){
						echo "\t\t[$fname] REQUIRE detectado: [$inc_file]\n";
						echo "\t\t[$fname] REQUIRE file.....: [$ifile]\n";
						echo "\t\t\t",$tokens[$tid][1],"\n";
						echo "\t\t\t",$tokens[$tid+1][1],"\n";
						echo "\t\t\t",$tokens[$tid+2][1],"\n";
						echo "\t\t\t",$tokens[$tid+3][1],"\n";
						echo "\t\t\t",$tokens[$tid+4][1],"\n";
					}

					// Arquivo existe?
					if(is_file($ifile)){
						// substituir essa linha pelo script de destino pre-compilado
						$reclevel++;
						$src = _php_implode($ifile, $curpwd);
						$reclevel--;
						if($ENABLE_DEBUG){
							echo "\n\t****** Fonte importado de [$ifile]\n";
							//print_r($src);
						}

						// jogar lista de tokens dentro do token atual,
						// _php_resume_inline_tokens vai resolver isso depois
						$tokens[$tid] = array(
							TOKEN_CODE => TOKEN_INLINE_LIST,
							TOKEN_CONTENT => $src,
							TOKEN_LINE => -1,
							TOKEN_NAME => 'TOKEN_INLINE_LIST',
							TOKEN_FQDN => $ifile
						);

						// eliminar tokens do require
						unset($tokens[$tid+1]);
						unset($tokens[$tid+2]);
						unset($tokens[$tid+3]);
						unset($tokens[$tid+4]);

					}else{
						// $content[$k] = "# REQUIRE impossivel, arquivo nao existe: ".$ifile."\n";
						if($ENABLE_DEBUG){
							echo "\t\t[$fname] DEBUG DE FALHA 9\n";
							echo "\t\t[$fname] REQUIRE file.....: [$ifile]\n";
							echo "\t\t\t",$tokens[$tid][1],"\n";
							echo "\t\t\t",$tokens[$tid+1][1],"\n";
							echo "\t\t\t",$tokens[$tid+2][1],"\n";
							echo "\t\t\t",$tokens[$tid+3][1],"\n";
							echo "\t\t\t",$tokens[$tid+4][1],"\n";
						}

						_abort("REQUIRE impossivel, arquivo nao existe: ".$ifile, 9);
					}

				// ignorar variavel na require, ignorar
				}elseif(
					$tokens[$tid][0] === T_REQUIRE &&
					$tokens[$tid+1][0] === T_OPEN_PARAM &&
					$tokens[$tid+2][0] === T_VARIABLE &&
					$tokens[$tid+3][0] === T_CLOSE_PARAM
				){
					if($ENABLE_DEBUG){
						echo "\t\t[$fname] DEBUG DE NOTA, variavel na REQUIRE\n";
						echo "\t\t[$fname] REQUIRE file.....: [$ifile]\n";
						echo "\t\t\t",$tokens[$tid][1],"\n";
						echo "\t\t\t",$tokens[$tid+1][1],"\n";
						echo "\t\t\t",$tokens[$tid+2][1],"\n";
						echo "\t\t\t",$tokens[$tid+3][1],"\n";
						echo "\t\t\t",$tokens[$tid+4][1],"\n";
					}

				}elseif( $tokens[$tid][0] === T_REQUIRE ){

					if($ENABLE_DEBUG){
						echo "\t\t[$fname] DEBUG DE FALHA 10\n";
						echo "\t\t[$fname] REQUIRE file.....: [$ifile]\n";
						echo "\t\t\t",$tokens[$tid][1],"\n";
						echo "\t\t\t",$tokens[$tid+1][1],"\n";
						echo "\t\t\t",$tokens[$tid+2][1],"\n";
						echo "\t\t\t",$tokens[$tid+3][1],"\n";
						echo "\t\t\t",$tokens[$tid+4][1],"\n";
					}

					_abort("REQUIRE impossivel, referencia com sequencia desconhecida de tokens: ".$ifile, 10);

				}
			} // if IMPLODE_REQUIRE == 1
		}

		// tokens resumidos
		return $tokens;
	}

	// transformar os tokens dentro de tokens em lista plana de todos os
	// tokens em serie
	$newtokenlist = array();
	$newtokencount = 0;
	function _php_resume_inline_tokens($tokens){
		global $newtokenlist;
		global $newtokencount;

		foreach($tokens as $tid=>$tk){
			if($tk[TOKEN_CODE] === TOKEN_INLINE_LIST){
				// lista de tokens, processar
				_php_resume_inline_tokens($tk[TOKEN_CONTENT]);
			}else{
				// token plano, catalogar
				$newtokenlist[$newtokencount] = $tk;
				$newtokencount++;
			}
		}
	}

	// transformar tokens em codigo-fonte
	function _php_tokens2source(&$tokens){
		// converter novo array em codigo novamente
		$tsrc = array(); $c = 0;
		foreach($tokens as $k=>$v) $tsrc[$c++] = $v[TOKEN_CONTENT];
		return implode('', $tsrc);
	}

// Funcoes
	function _abort($error, $errno=1){
		global $INPUT_SCRIPT ;
		echo "\n";
		echo "PHP-IMPLODE [", $INPUT_SCRIPT, "] ERROR: ", $error, "\n";
		echo "\n";
		exit($errno);
	}

	function _help(){
		echo "\n";
		echo "Use: php-implode -f (php-script) -w (output-script) [-r relative-chroot] [options]\n";
		echo "Options:\n";
		echo "\t-c        Limpar codigo\n";
		echo "\t-d        Ativar debug\n";
		echo "\t-x        Transformar partes HTML em tokens PHP\n";
		echo "\t-M        Nao resumir require()\n";
		echo "\t-B        Inserir quebra de linhas em separadores\n";
		echo "\t-C        Desativar cache\n";
		echo "\t-T        Especificar diretorio de cache\n";
		echo "\n";
		exit(0);
	}

	// retirar /./, ./., //
	function _clspath($str){
		for($i=0; $i < 10; $i++){
			$str = str_replace('//', '/', $str);
			$str = str_replace('/./', '/', $str);
		}
		return $str;
	}


// Remover $root do inicio para considerar caminho 100% relativo
	function _no_root($in_phpfile){
		global $root;
		global $ENABLE_DEBUG;
		$phpfile = $in_phpfile;
		$rlen = strlen($root);

		if($root != '/' && substr($phpfile, 0, $rlen) == $root) $phpfile = substr($phpfile, $rlen);
		$phpfile = str_replace('//', '/', $phpfile);

		if($ENABLE_DEBUG){
			echo "\n";
			echo "_no_root($phpfile)\n";
			echo "       PHP-input-file......: [$in_phpfile]\n";
			echo "           compsubstr......: [".substr($in_phpfile, 0, strlen($root))."]\n";
			echo "                 rlen......: [".$rlen."]\n";
			echo "       out-PHP-file........: [$phpfile]\n";
			echo "\n";
		}
		return $phpfile;
	}
// Adicionar root para obter caminho completo para acessar o arquivo
	function _full_file($in_phpfile){
		global $root;
		global $ENABLE_DEBUG;
		$phpfile = $in_phpfile;
		if($root=='/') return $phpfile;
		$phpfile = $root . _no_root($phpfile);
		if($ENABLE_DEBUG) echo "_full_file($in_phpfile) root[$root] out[$phpfile]\n";
		return $phpfile;
	}

// ************************************************************************************************************

// Variaveis GLOBAIS
	// Script de entrada
	$INPUT_SCRIPT = '';

	// Arquivo para gravar script de saida
	$startpwd = getcwd();
	$OUTPUT_SCRIPT = '';

	// Root relativo (procurar dentro de uma pasta em vez de ir no /)
	$root = '/';

	// Flags
	// - remover comentarios?
	$PHPSTRIPCLEAN = 0;

	// Converter HTML em tokens PHP
	$PHPIZE_HTML = 0;

	// Nao implodir inclusoes via require()
	$IMPLODE_REQUIRE = 1;

	// Inserir quebra de linha em todos os separadores ';' para
	// ajudar na depuracao
	$INSERT_BREAK = 0;

	// Cache
	// o cache de tokens do script
	$CACHE_ENABLE = 1;
	$CACHEDIR = '/ram/tmp';
	$CACHEPREFIX = 'phpi-cache-' . $PHPI_VERSION;

	$ENABLE_DEBUG = 0;

	// processar argumento
	if(isset($argv[0])) unset($argv[0]); // remover argumento zero
	foreach($argv as $k=>$arg){
		if(!isset($argv[$k])) continue;

		if($arg=='-h' || $arg == '-help' || $arg == '--help') _help();

		$next = isset($argv[$k+1]) ? $argv[$k+1] : '';

		// ativar debug
		if($arg=='-d'||$arg=='-debug'||$arg=='--debug'){
			$ENABLE_DEBUG++;
			unset($argv[$k]);
			continue;
		}

		// Arquivo de entrada
		if( ($arg=='-f' || $arg=='-input' || $arg=='--input' || $arg=='-file' || $arg=='--file') && $next != ''){
			$INPUT_SCRIPT = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// HTML para php
		if($arg=='-x' || $arg=='-phpize' || $arg=='--phpize'){
			$PHPIZE_HTML++;
			unset($argv[$k]);
			continue;
		}

		// Inserir quebra em separadores
		if($arg=='-B' || $arg=='-break' || $arg=='--break'){
			$INSERT_BREAK++;
			unset($argv[$k]);
			continue;
		}

		// Desativar cache
		if($arg=='-C' || $arg=='-no-cache' || $arg=='-nocache' || $arg=='--nocache' || $arg=='--no-cache'){
			$CACHE_ENABLE=0;
			unset($argv[$k]);
			continue;
		}

		// Diretorio de cache
		if( ($arg=='-T' || $arg=='-cachedir' || $arg=='--cachedir') && $next != ''){
			$CACHEDIR = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Arquivo de saida
		if( ($arg=='-w' || $arg=='-output' || $arg=='--output') && $next != ''){
			$OUTPUT_SCRIPT = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Nao implodir require()
		if( $arg=='-M' || $arg=='-no-require' || $arg=='--no-require'){
			$IMPLODE_REQUIRE = 0;
			unset($argv[$k]);
			continue;
		}

		// Root relativo
		if( ($arg=='-r' || $arg=='-root' || $arg=='--root' ) && $next != ''){
			$root = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Flags
		if($arg == '-c' || $arg == '-clean' || $arg == '-clear' || $arg == '--clean' || $arg == '--clear'){
			$PHPSTRIPCLEAN++;
			continue;
		}

		// Argumento desconhecido:
		// 1 - se for arquivo existente, e' nosso script
		if($INPUT_SCRIPT =='' && is_file($arg)){ $INPUT_SCRIPT = $arg; continue; }
		if($OUTPUT_SCRIPT==''){ $OUTPUT_SCRIPT = $arg; continue; }
	}
	if($root=='') $root = '/';

	$INPUT_SCRIPT = _clspath($INPUT_SCRIPT);
	$OUTPUT_SCRIPT = _clspath($OUTPUT_SCRIPT);

// Debug
	if($ENABLE_DEBUG){
		echo "START PWD........: [$startpwd]\n";
		echo "SCRIPT...........: [$INPUT_SCRIPT]\n";
		echo "OUT FILE.........: [$OUTPUT_SCRIPT]\n";
		echo "CLEAN............: [$PHPSTRIPCLEAN]\n";
		echo "PHPIZE HTML......: [$PHPIZE_HTML]\n";
		echo "IMPLODE_REQUIRE..: [$IMPLODE_REQUIRE]\n";
		echo "ROOT.........: [$root]\n";
		// exit();
	}

// Criticas
	if($INPUT_SCRIPT==''){ _abort("Arquivo [$INPUT_SCRIPT] nao informado.", 10); }
	if(!file_exists($INPUT_SCRIPT)){ _abort("Arquivo [$INPUT_SCRIPT] nao encontrado.", 11); }


// Considerar todas as referencias dentro da jaula $root
// vamos remover a referencia do chroot do script de entrada
// para que a funcao _php_implode possa adicionar o $root
// --
// Obter arquivo implodido
	$rscript = _no_root($INPUT_SCRIPT);
	if($ENABLE_DEBUG){
		echo "\n";
		echo "Script: [$INPUT_SCRIPT] R-Script: [$rscript]\n";
		echo "\n";
		// exit();
	}

	// obter todos os tokens implodidos do arquivo principal
		/*
		$alltokens = php_tokenizer_file($rscript);
		if($ENABLE_DEBUG){
			echo "TOKENS DO ARQUIVO DE ENTRADA:\n";
			echo "-------------------------------------------------\n";
			print_r($alltokens);
			echo "\n";
			echo "-------------------------------------------------\n";
			echo _php_tokens2source($alltokens);
			echo "\n";
			echo "-------------------------------------------------\n";
			exit();
		}
		*/
	// obter tokens do arquivo e seguir requires recursivamente
	$alltokens = _php_implode($rscript, '');

	// transformar tokens com filhos em lista planificada
	// - retorna em $newtokenlist
	_php_resume_inline_tokens($alltokens);

	// converter tokens HTML em PHP
	if($PHPIZE_HTML) _php_convert_html($newtokenlist);

	// remover whitespaces desnecessarios
	if($PHPSTRIPCLEAN) _php_clean($newtokenlist);

	if($ENABLE_DEBUG > 1){ echo "TOKENS POS CONVERSAO HTML->PHP\n"; print_r($newtokenlist); }
	// exit();

	// liberar memoria
	unset($alltokens);

	// lista de tokens final
	$final_tokens = array();

	// re-incluir bordas de codigo html/php
	$php_status = 0; // 0=php fechado (modo HTML), 1=php aberto (modo PHP)
	$c = 0;

	// num codigo 100% php, o primeiro token e' abertura para PHP

	// Adicionar open/close tab
	foreach($newtokenlist as $k => $token){
		if($token[TOKEN_CODE]===T_INLINE_HTML){
			// string html
			if($php_status){
				// codigo php esta aberto, FECHAR
				$final_tokens[$c++] = array(
					TOKEN_CODE => T_CLOSE_TAG,
					TOKEN_CONTENT => ' ?>',
					TOKEN_LINE => -1,
					TOKEN_NAME => 'T_CLOSE_TAG'
				);
			//}else{
				// php fechado, estamos em HTML, continuando em HTML
			}
			// inserir codigo HTML
			$final_tokens[$c++] = $token;
			// passar ultimo token para HTML
			$php_status = 0;
		}else{
			// ultimo token nao era PHP, era HTML, colocar abertura
			if(!$php_status){
				// codigo php esta aberto, FECHAR
				$final_tokens[$c++] = array(
					TOKEN_CODE => T_CLOSE_TAG,
					TOKEN_CONTENT => '<?php ',
					TOKEN_LINE => -1,
					TOKEN_NAME => 'T_OPEN_TAG'
				);
			}
			// token PHP
			$final_tokens[$c++] = $token;
			// passar ultimo token para PHP
			$php_status = 1;
		}
		// liberar memoria enquanto copio para nova lista
		unset($newtokenlist[$k]);
	}
	// nao importa o modo como terminou, nao precisa fechar tag PHP

	// Inserir quebra de linha
	if($INSERT_BREAK)
		foreach($final_tokens as $k=>$token){
			switch($token[TOKEN_CODE]){
				case T_OPEN_TAG:
				case T_HTML_TO_PHP:
				case T_SEPARATOR:
				case T_OPEN_BLOCK:
				case T_CLOSE_BLOCK:
				case T_CLOSE_BLOCK:
					$final_tokens[$k][TOKEN_CONTENT] .= "\n";
					break;
			}
		}
	//-

	if($ENABLE_DEBUG > 1){
		echo "TOKENS FINAIS 1\n";
		print_r($final_tokens);
	}

	// converter novo array em codigo novamente
	foreach($final_tokens as $k=>$v) $final_tokens[$k] = $v[TOKEN_CONTENT];
	$newscript = implode('', $final_tokens);

// Trocar constantes de compilacao
	$consts = array(
		'COMPILER_MIN_TIMESTAMP' => (@time()) - 86400,			// tempo minimo para executar programas compilados
		'COMPILER_TIMESTAMP' => @time(),						// timstamp da compilacao
		'COMPILER_MONTHONLY' => @date('m'),						// mes da compilacao
		'COMPILER_YEARONLY' => @date('Y'),						// ano da compilacao
		'COMPILER_DAYONLY' => @date('d'),						// dia da compilacao
		'COMPILER_DATET' => @date("d/m/Y H:i:s"),				// data/hora da compilacao
		'COMPILER_DATE' => @date("d/m/Y"),						// data da compilacao
		'COMPILER_TIME' => @date("H:i:s")						// hora da compilacao
	);
	foreach($consts as $cname=>$cvalue) $newscript = str_replace($cname, $cvalue, $newscript);

	if($ENABLE_DEBUG > 1){
		echo "OUT SCRIPT.: [$OUTPUT_SCRIPT]\n";
		echo "-------------------------------------------------------------\n";
		echo $newscript,"\n";
		echo "-------------------------------------------------------------\n";
	}

// Gravar em arquivo ou jogar na saida?
	if($OUTPUT_SCRIPT==''){
		// Saida
		echo $newscript;
		echo "\n";
	}else{
		// Arquivo
		//- echo "Gravando no arquivo: [$OUTPUT_SCRIPT] pwd=[$startpwd]\n";
		chdir($startpwd);
		file_put_contents($OUTPUT_SCRIPT, $newscript);
	}







?>
