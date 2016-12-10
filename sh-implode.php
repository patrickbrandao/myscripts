#!/usr/bin/php -q
<?php

// Variaveis
	// Script de entrada
	$INPUT_SCRIPT = '';

	// Arquivo para gravar script de saida
	$startpwd = getcwd();
	$OUTPUT_SCRIPT = '';

	// Root relativo (procurar dentro de uma pasta em vez de ir no /)
	$root = '/';

	// Flags
	// - remover comentarios?
	$clean = 0;

	$debug = 0;

// Funcoes
	function _abort($error, $errno=1){
		global $INPUT_SCRIPT ;
		echo "\n";
		echo "SH-IMPLODE [", $INPUT_SCRIPT, "] ERROR: ", $error, "\n";
		echo "\n";
		exit($errno);
	}

	function _help(){
		echo "\n";
		echo "Use: sh-implode -f (shell-script) -w (output-script) [-r relative-chroot]\n";
		echo "\n";
		exit(0);
	}
	
	// processar argumento
	if(isset($argv[0])) unset($argv[0]); // remover argumento zero
	foreach($argv as $k=>$arg){
		if(!isset($argv[$k])) continue;

		if($arg=='-h' || $arg == '-help' || $arg == '--help') _help();

		$next = isset($argv[$k+1]) ? $argv[$k+1] : '';

		// ativar debug
		if($arg=='-d'||$arg=='-debug'||$arg=='--debug'){
			$debug++;
			unset($argv[$k]);
			continue;
		}

		// Arquivo de entrada
		if($arg=='-f' && $next != ''){
			$INPUT_SCRIPT = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Arquivo de saida
		if($arg=='-w' && $next != ''){
			$OUTPUT_SCRIPT = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Root relativo
		if($arg=='-r' && $next != ''){
			$root = $next;
			unset($argv[$k]); unset($argv[$k+1]);
			continue;
		}

		// Flags
		if($arg == '-c'){ $clean++; continue; }

		// Argumento desconhecido:
		// 1 - se for arquivo existente, e' nosso script
		if($INPUT_SCRIPT =='' && is_file($arg)){ $INPUT_SCRIPT = $arg; continue; }
		if($OUTPUT_SCRIPT==''){ $OUTPUT_SCRIPT = $arg; continue; }
	}
	if($root=='') $root = '/';

	// retirar /./, ./., //
	function _clspath($str){
		for($i=0; $i < 10; $i++){
			$str = str_replace('//', '/', $str);
			$str = str_replace('/./', '/', $str);
		}
		return $str;
	}
	$INPUT_SCRIPT = _clspath($INPUT_SCRIPT);
	$OUTPUT_SCRIPT = _clspath($OUTPUT_SCRIPT);

// Debug
	if($debug){
		echo "SCRIPT.....: [$INPUT_SCRIPT]\n";
		echo "OUT FILE...: [$OUTPUT_SCRIPT]\n";
		echo "ROOT.......: [$root]\n";
		// exit();
	}

// Criticas
	if($INPUT_SCRIPT==''){ _abort("Arquivo [$INPUT_SCRIPT] nao informado.", 10); }
	if(!file_exists($INPUT_SCRIPT)){ _abort("Arquivo [$INPUT_SCRIPT] nao encontrado.", 11); }

// Lista de arquivos incluidos
	$includes = array();

// Remover $root do inicio para considerar caminho 100% relativo
	function _no_root($in_shfile){
		global $root;
		global $debug;
		$shfile = $in_shfile;
		$rlen = strlen($root);

		if($root != '/' && substr($shfile, 0, $rlen) == $root) $shfile = substr($shfile, $rlen);
		$shfile = str_replace('//', '/', $shfile);

		if($debug){
			echo "\n";
			echo "_no_root($shfile)\n";
			echo "           shfile....: [$in_shfile]\n";
			echo "           compsubstr: [".substr($in_shfile, 0, strlen($root))."]\n";
			echo "                 rlen: [".$rlen."]\n";
			echo "       out-shfile....: [$shfile]\n";
			echo "\n";
		}
		return $shfile;
	}
// Adicionar root para obter caminho completo para acessar o arquivo
	function _full_file($in_shfile){
		global $root;
		global $debug;
		$shfile = $in_shfile;
		if($root=='/') return $shfile;
		$shfile = $root . _no_root($shfile);
		if($debug) echo "_full_file($in_shfile) root[$root] out[$shfile]\n";
		return $shfile;
	}

// Funcao para implodir script
	$reclevel = 0;
	function _sh_implode($in_shfile, $curpwd){
		global $includes;
		global $reclevel;
		global $debug;

		// Obter caminho completo para o script
		$shfile = _full_file($in_shfile);

		// Obter informacoes
		$pi = pathinfo($shfile);
		$fname = $pi['basename'];
		$dname = $pi['dirname'];
		if($dname=='.') $dname = $curpwd;
		$sfqdn = $dname.'/'.$fname;

		if($curpwd=='') $curpwd = $dname;

		$linenum = 0;

		if($debug){
			echo "_sh_implode($in_shfile, $curpwd)\n";
			echo "\tscript name......: [$sfqdn]\n";
			echo "\tfile name........: [$fname]\n";
			echo "\tdir name.........: [$dname]\n";
			echo "\tcur pwd..........: [$curpwd]\n";
			echo "\n";
		}

		// entrar no diretorio para procurar includes relativas
		if(is_dir($dname)) @chdir($dname);

		$includes[$sfqdn] = isset($includes[$sfqdn]) ? $includes[$sfqdn]+1 : 1;
		if($includes[$sfqdn] > 2){
			//- echo "-> Erro, inclusoes em loop do arquivo [$sfqdn]\n";
			exit(4);
		}

		// Obter codigo fonte
		$content = @file($shfile);
		$newcontent = array();

		// Processar linha a linha
		foreach($content as $k=>$line){
			$sline = trim($line);
			$fc = substr($sline, 0, 1);
			$sc = substr($sline, 1, 1);

			// remover primeira linha do script destino se for chamado de /bin/bash
			if($reclevel && $linenum==0 && $sline == '#!/bin/sh'){
				unset($content[$k]);
				continue;
			}

			// include detectado
			if($fc == '.' && $sc == ' '){
				$inc_file = trim(substr($sline, 2));

				// ingnorar includes com variaveis, elas nao podem
				// ser implodicas e funcionam se existirem em shell-script
				// (PERIGO DE BUG se o alvo estiver criptografado tambem)
				if(strpos($inc_file, '$')!==false) continue;

				$ifile = _full_file($inc_file);

				if($debug){
					echo "\t\t[$fname] Include detectado na linha [$linenum] [$sline]\n";
					echo "\t\t[$fname] Include file: [$ifile]\n";
				}

				// Arquivo existe?
				if(is_file($ifile)){
					// substituir essa linha pelo script de destino pre-compilado
					$reclevel++;
					$content[$k] = _sh_implode($ifile, $curpwd);
					$reclevel--;
				}else{
					// $content[$k] = "# Include impossivel, arquivo nao existe: ".$ifile."\n";
					_abort("Include impossivel, arquivo nao existe: ".$ifile, 9);
				}
			}

			$linenum++;
		}

		// reunir linhas novamente
		return implode("", $content)."\n";
	}

// Considerar todas as referencias dentro da jaula $root
// vamos remover a referencia do chroot do script de entrada
// para que a funcao _sh_implode possa adicionar o $root
// --
// Obter arquivo implodido
	$rscript = _no_root($INPUT_SCRIPT);
	if($debug){
		echo "\n";
		echo "Script: [$INPUT_SCRIPT] R-Script: [$rscript]\n";
		echo "\n";
		// exit();
	}

	$newscript = _sh_implode($rscript, '');

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

	if($debug > 1){
		echo "OUT SCRIPT.: [$OUTPUT_SCRIPT]\n";
		echo "-------------------------------------------------------------\n";
		echo $newscript;
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
