#!/usr/bin/php -q
<?php

// Analisar arquivo e aplica organizacao de tabs
// baseado em chaves

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

	// Quantas tabs aplicar ?
	$TABS = 1;

// Funcoes
	function _abort($error, $errno=1){
		global $INPUT_FILE ;
		echo "\n";
		echo "FILE-SET-TABS ABORTED [", $INPUT_FILE, "] ERROR: ", $error, "\n";
		echo "\n";
		exit($errno);
	}

	function _help(){
		echo "\n";
		echo "Use: file-set-tabs [options] -f (file) [-w (output-file)]\n";
		echo "\n";
		echo " -f (file)    Arquivo de entrada\n";
		echo " -w (file)    Arquivo de saida\n";
		echo " -i           Grava resultado no mesmo arquivo de entrada (sem -w)\n";
		echo " -B           Adicionar quebra de linha ao final do arquivo";
		echo " -T           Incrementa numero de tabs por nivel (padrao 1)";
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
		if($arg=='-t'||$arg=='-tab'||$arg=='--tab'){ $TABS++; unset($argv[$k]); continue; }

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
		echo "[debug] TABS.......: [$TABS]\n";
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