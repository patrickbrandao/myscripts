#!/usr/bin/php -q
<?php

// Limpador de arquivos
// Remover comentarios e conteudo desnecessario em arquivos de configuracao

// Variaveis
	// Arquivo de entrada
	$INPUT_FILE = '';

	// Arquivo de saida
	$OUTPUT_FILE = '';

	// Tipo de limpeza
	/*
		1 = arquivo de texto, remover comentarios com # no inicio da linha, remover linhas vazias, trim nas linhas
		2 = definicao mysql, interpretar tokens
		3 = definicao INI, remover comentarios com # no inicio da linha e linhas vazias, trim nas linhas
		4 = bash, interpretar tokens
		5 = bindconf, arquivo de configuracao do Bind, trim nas linhas
		6 = bindzone, arquivo de zona do Bind, trim nas linhas
		7 = arquivo conf, comentarios comecando com ; ou #, sem linhas vazias, trim nas linhas
	*/
	$CLEANTYPE = 0;

	// Opcoes de limpeza (pre-interpretacao)
	//                          Acoes quando acionar:
	$FLAGS = array(
		'linetrim' => 0,		// limpar espaco ao redor das linhas
		'emptyline' => 0,		// remover linhas em branco
		'chashstart' => 0,		// remover linhas comecando com #
		'chashend' => 0,		// remover linhas comecando com #
		'csemicolon' => 0,		// remover linhas comecando com ;
		'cdbarstart' => 0,		// remover linhas comecando com //
		'cdbarend' => 0,		// remover tudo apos um // ate o fim da linha
		'cblock' => 0,			// remover linhas comecando com bloco de comentario /* */
		'doublespace' => 0,		// trocar espacos duplos por unico
		'doubletab' => 0,		// trocar tabs duplas por unica
		'tabspace' => 0,		// trocar tabs por espacos
		'nocr' => 0				// remover quebra de linha (nao incluso no flag-all)
	);

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
		echo "FILE-CLEANER ABORTED [", $INPUT_FILE, "] ERROR: ", $error, "\n";
		echo "\n";
		exit($errno);
	}

	function _help(){
		echo "\n";
		echo "Use: file-cleaner [options] -f (file) [-w (output-file)]\n";
		echo "\n";
		echo " -f (file)    Arquivo de entrada\n";
		echo " -w (file)    Arquivo de saida\n";
		echo " -i           Grava resultado no mesmo arquivo de entrada (sem -w)\n";
		echo " -B           Adicionar quebra de linha ao final do arquivo";
		echo " -F (flag)    Limpar guiado por flags\n";
		echo "                linetrim     = espaco ao redor das linhas\n";
		echo "                emptyline    = linhas em branco\n";
		echo "                chashstart   = linhas comecando com #\n";
		echo "                chashend     = apos um # ate o fim da linha\n";
		echo "                csemicolon   = linhas comecando com ;\n";
		echo "                cdbarstart   = linhas comecando com //\n";
		echo "                cdbarend     = apos um // ate o fim da linha\n";
		echo "                doublespace  = trocar espacos duplos por unico\n";
		echo "                doubletab    = trocar tabs duplas por unica\n";
		echo "                tabspace     = trocar tabs por espacos\n";
		echo "                cblock       = linhas comecando com bloco de comentario /* */\n";
		echo "                flag-all     = ativar todas as flags acima\n";
		echo "                nocr         = remover quebra de linha\n";
		echo "\n";
		echo " -t (type)    Limpar baseado no tipo de conteudo\n";
		echo "                0: none      = sem tipo, instrucoes com flags\n";
		echo "                1: plain     = #, full-trim, no-empty-lines\n";
		echo "                2: mysql-def = #, full-trim, no-empty-lines, no-break\n";
		echo "                3: ini       = #, full-trim, no-empty-lines\n";
		echo "                4: bash      = #, full-trim, no-empty-lines\n";
		echo "                5: bindconf  = ;, full-trim, no-empty-lines\n";
		echo "                6: bindzone  = ;, full-trim, no-empty-lines\n";
		echo "                7: conf      = ;#, full-trim, no-empty-lines\n";
		echo "\n";
		exit(0);
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

		// Flags
		// - ativar flags mencionadas
		if($arg=='-F' && $next !=''){ $arg=$next;unset($argv[$k+1]); }
		if($arg == 'linetrim'){ $FLAGS['linetrim'] = 1; unset($argv[$k]); continue; }
		if($arg == 'emptyline'){ $FLAGS['emptyline'] = 1; unset($argv[$k]); continue; }
		if($arg == 'chashstart'){ $FLAGS['chashstart'] = 1; unset($argv[$k]); continue; }
		if($arg == 'chashend'){ $FLAGS['chashend'] = 1; unset($argv[$k]); continue; }
		if($arg == 'csemicolon'){ $FLAGS['csemicolon'] = 1; unset($argv[$k]); continue; }
		if($arg == 'cdbarstart'){ $FLAGS['cdbarstart'] = 1; unset($argv[$k]); continue; }
		if($arg == 'cdbarend'){ $FLAGS['cdbarend'] = 1; unset($argv[$k]); continue; }
		if($arg == 'cblock'){ $FLAGS['cblock'] = 1; unset($argv[$k]); continue; }
		if($arg == 'doublespace'){ $FLAGS['doublespace'] = 1; unset($argv[$k]); continue; }
		if($arg == 'doubletab'){ $FLAGS['doubletab'] = 1; unset($argv[$k]); continue; }
		if($arg == 'tabspace'){ $FLAGS['tabspace'] = 1; unset($argv[$k]); continue; }
		if($arg == 'nocr'){ $FLAGS['nocr'] = 1; unset($argv[$k]); continue; }

		// - ativar todos
		if($arg == 'flag-all'||$arg == 'flagall'||$arg=='all-flags'||$arg=='allflags'){
			$FLAGS['linetrim'] = 1;
			$FLAGS['emptyline'] = 1;
			$FLAGS['chashstart'] = 1;
			$FLAGS['chashend'] = 1;
			$FLAGS['csemicolon'] = 1;
			$FLAGS['cdbarstart'] = 1;
			$FLAGS['cdbarend'] = 1;
			$FLAGS['cblock'] = 1;
			$FLAGS['doublespace'] = 1;
			$FLAGS['doubletab'] = 1;
			$FLAGS['tabspace'] = 1;
			unset($argv[$k]);
			continue;
		}

		// Tipos
		if( ($arg == '-t' || $arg =='-type' || $arg =='--type') && $next != ''){
			$tmp = strtolower($next);
			switch($tmp){
				case '0': case 'none': $CLEANTYPE = 0; break;
				case '1': case 'plain': $CLEANTYPE = 1; break;
				case '2': case 'mysql-def': case 'mysqldef': $CLEANTYPE = 2; break;
				case '3': case 'ini': $CLEANTYPE = 3; break;
				case '4': case 'bash': $CLEANTYPE = 4; break;
				case '5': case 'bindconf': $CLEANTYPE = 5; break;
				case '6': case 'bindzone': $CLEANTYPE = 6; break;
				case '7': case 'conf': $CLEANTYPE = 7; break;
			}
			unset($argv[$k]); unset($argv[$k+1]); continue;
		}
		// tipo como argumento
		$tmp = 0;
		switch($arg){
			case 'none': $CLEANTYPE = 0; $tmp = 1; break;
			case 'plain': $CLEANTYPE = 1; $tmp = 1; break;
			case 'mysql-def': case 'mysqldef': $CLEANTYPE = 2; $tmp = 1; break;
			case 'ini': $CLEANTYPE = 3; $tmp = 1; break;
			case 'bash': $CLEANTYPE = 4; $tmp = 1; break;
			case 'bindconf': $CLEANTYPE = 5; $tmp = 1; break;
			case 'bindzone': $CLEANTYPE = 6; $tmp = 1; break;
			case 'conf': $CLEANTYPE = 7; $tmp = 1; break;
		}
		if($tmp){ unset($argv[$k]); continue; }

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
		echo "[debug] CLEANTYPE..: [$CLEANTYPE]\n";
		echo "[debug] DEBUG LEVEL: [$DEBUG]\n";
		//echo "[debug] FLAGS......: [",implode(', ', array_keys($FLAGS)),"]\n";
		// exit();
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

// Ativar flags rapidas relacionada a tipos:
	// FALTA FAZER

// Pre-Limpeza
	for($ci=1; $ci <= 3; $ci++){

		if($DEBUG){ echo "[debug] Iniciando pre-limpeza (parte ",$ci,")","\n"; }

		// :: cblock :: REMOVER BLOCK DE COMENTARIOS /* */
		if($FLAGS['cblock']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: cblock, ini-len: ",$inilen," bytes\n"; }

			// posicao de inicio da analise,
			// avancar para posicao de inicio do ultimo comentario encontrado
			$pstart = 0;
			$slen = $inilen;
			$offset = 0;
			while(true){
				// procurar comentario
				//echo "---> PROCURANDO OFF-SET [$p] SLEN[$slen]\n";

				// estrapolou string? Reiniciar
				if($offset >= $slen) $offset = 0;

				// procurar abertura de comentario
				$offset = strpos($file_content, '/*', $offset);
				if($offset===false){
					// nao achou mais, parar
					break;
				}else{
					// achou alguma coisa
					// procurar fim
					$e = strpos($file_content, '*/', $offset + 2);
					if($e===false){
						// nao achou o fim, parar
						break;
					}else{
						// achou o fim
						// - parte 1, do inicio do texto ao caracter antes do comentario
						$part1 = substr($file_content, 0, $offset-1);
						// - parte 2, do fim do comentario ao fim do texto
						$part2 = substr($file_content, $e+2);
						// = juntar as partes pulando o comentario
						$file_content = $part1 . $part2;
						unset($part1); unset($part2);

						// caso nova string seja menor que ultima posicao, parar
						$slen = strlen($file_content);
						$offset = $e;
					}
				}
			};
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: cblock, end-len: ",$endlen," bytes\n"; }
		}
		// :: linetrim :: LIMPAR LINHAS
		if($FLAGS['linetrim']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: linetrim, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v) $a[$k] = trim($v);
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: linetrim, end-len: ",$endlen," bytes\n"; }
		}
		// :: emptyline :: REMOVER LINHAS VAZIAS
		if($FLAGS['linetrim']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: emptyline, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v) if($v=='') unset($a[$k]);
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: emptyline, end-len: ",$endlen," bytes\n"; }
		}
		// :: chashstart :: REMOVER COMENTARIOS QUE INICIAM COM HASH '#'
		if($FLAGS['chashstart']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: chashstart, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v) if(substr(trim($v), 0, 1)==='#') unset($a[$k]);
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: chashstart, end-len: ",$endlen," bytes\n"; }
		}
		// :: cdbarend :: REMOVER COMENTARIOS APOS O HASH '#'
		if($FLAGS['chashend']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: chashend, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v){
				$tmp = strpos($v, '#');
				if($tmp!==false) $a[$k] = substr($v, 0, $tmp);
			}
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: chashend, end-len: ",$endlen," bytes\n"; }
		}
		// :: csemicolon :: REMOVER COMENTARIOS QUE INICIAM COM PONTO E VIRGULA ';'
		if($FLAGS['csemicolon']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: csemicolon, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v) if(substr(trim($v), 0, 1)===';') unset($a[$k]);
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: csemicolon, end-len: ",$endlen," bytes\n"; }
		}
		// :: cdbarstart :: REMOVER COMENTARIOS QUE INICIAM COM BARRA DUPLA '//'
		if($FLAGS['cdbarstart']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: cdbarstart, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v) if(substr(trim($v), 0, 1)==='//') unset($a[$k]);
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: cdbarstart, end-len: ",$endlen," bytes\n"; }
		}
		// :: cdbarend :: REMOVER COMENTARIOS APOS A BARRA DUPLA '//'
		if($FLAGS['cdbarend']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: cdbarend, ini-len: ",$inilen," bytes\n"; }
			$a = explode("\n", $file_content);
			foreach ($a as $k => $v){
				$tmp = strpos($v, '//');
				if($tmp!==false) $a[$k] = substr($v, 0, $tmp);
			}
			$file_content = implode("\n", $a); unset($a);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: cdbarend, end-len: ",$endlen," bytes\n"; }
		}

		// :: tabspace :: TROCAR TABS POR ESPACOS
		if($FLAGS['tabspace']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: tabspace, ini-len: ",$inilen," bytes\n"; }
			$file_content = str_replace("\t", " ", $file_content);
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: tabspace, end-len: ",$endlen," bytes\n"; }
		}

		// :: doublespace :: TROCAR ESPACOS DUPLOS POR ESPACO UNICO
		if($FLAGS['doublespace']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: doublespace, ini-len: ",$inilen," bytes\n"; }
			while(strpos($file_content, '  ')!==false)
				$file_content = str_replace('  ', ' ', $file_content);
			//-
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: doublespace, end-len: ",$endlen," bytes\n"; }
		}

		// :: doubletab :: TROCAR TABS DUPLOS POR TAB UNICA
		if($FLAGS['doubletab']){
			$inilen = strlen($file_content);
			if($DEBUG){ echo "[debug] Pre-limpeza: doubletab, ini-len: ",$inilen," bytes\n"; }
			while(strpos($file_content, "\t\t")!==false)
				$file_content = str_replace("\t\t", "\t", $file_content);
			//-
			$endlen = strlen($file_content);
			$file_ecolen += ($inilen - $endlen);
			if($DEBUG){ echo "[debug] Pre-limpeza: doubletab, end-len: ",$endlen," bytes\n"; }
		}

	} // for ci 1-2-3

	// :: nocr :: SEM QUEBRA DE LINHA
	if($FLAGS['nocr']){
		$inilen = strlen($file_content);
		if($DEBUG){ echo "[debug] Pre-limpeza: nocr, ini-len: ",$inilen," bytes\n"; }
		$file_content = str_replace("\n", "", $file_content);
		$endlen = strlen($file_content);
		$file_ecolen += ($inilen - $endlen);
		if($DEBUG){ echo "[debug] Pre-limpeza: nocr, end-len: ",$endlen," bytes\n"; }
	}


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