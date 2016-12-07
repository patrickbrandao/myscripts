#!/usr/bin/php -q
<?php

	/*
	
		Sistema anti-colisao de arquivos em multi-projetos
		
		Carrega lista de arquivo em diretorios que possuem como conteudo
		a mesma extrutura, e compara se há arquivos repetidos, pois
		uma vez que todos eles foram unidos numa so pasta, arquivos
		com o mesmo nome em projetos diferentes
	*/



	function find($dir){
		static $level = 0;
		$list = array();
		$level++;
		$d = dir($dir);
		while (false !== ($entry = $d->read())) {
			if($entry=='.'||$entry=='..') continue;
			if(substr($entry, 0, 1)=='.') continue;
			$full = str_replace('//', '/', $dir.'/'.$entry);
			
			// processar diretorio em recursividade
			if(is_dir($full)){
				echo str_repeat("\t", $level) . "[D] " . $entry."\n";
				$local = find($full);
				foreach($local as $k=>$v) $list[$k] = $v;
			}

			// links
			if(is_link($full)){
				echo str_repeat("\t", $level) . "[L] " . $entry."\n";
			}else{
				echo str_repeat("\t", $level) . "[!] " . $entry."\n";
			}

			// catalogar arquivo
			$fs = filesize($full);
			$list[$full] = $fs;
		}
		$d->close();
		$level--;
		return $list;
	}




// -- FUNCOES -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-################
	// compilador de PHP, gerar string universal e mapa de posicoes
	function fatal($e){
		echo "\n";
		echo "ERRO:\n\t".$e."\n";
		echo "\n";
		exit(2);
	}
	function usage($e=''){
		global $SKY_VERSION;
		global $SKY_RELEASE;
		if($e!='') echo "ERRO: ".$e."\n";
		echo "Analisador anti-colisao de arquivos", "\n";
		echo "Autor: Patrick Brandao <patrickbrandao@gmail.com>", "\n";
		echo "Use: dupfiles [opcoes] [diretorios]\n";
		echo "  Opcoes:\n";
		echo "  Use: 'ignore=regex_entry'\n";
		echo "        Usa exprssao 'regex_entry'para ignorar arquivos que podem se repetir sem problemas\n";
		echo "\n\n";
		echo '  dupfiles                     - Erro, falta de diretorios',"\n";
		echo '  dupfiles /tmp                - Erro, precisa de mais de um diretorio para comparar',"\n";
		echo '  dupfiles /a  /b              - Verifica se arquivos de /a estao contidos em /b e vice-versa',"\n";
		echo '  dupfiles /a /b ignore=readme - Compara ignorando arquivos com -readme- no nome',"\n";

		echo "\n";
		exit(1);
	}
// -- CONFIGURACOES -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=################

	// remover nome do programa da lista de argumentos
	if(isset($argv[0])) unset($argv[0]);

	// Parametros:
	$FILES = array();			// arquivos de ambos os diretorios listados sem o caminho do diretorio
	$DIRS = array();			// diretorios com arquivos
	$IGNORES = array();			// lista de expressoes para ignorar arquivos

	// processar argumentos
	$C = 0;
	foreach($argv as $xn=>$arg){
		$n = $xn;

		$arg = trim($arg);

		// Opcoes singulares -----------------------------------------------------
		if($arg=='-h' || $arg=='--help' || $arg=='help') usage();

		// Opcoes compostas -----------------------------------------------------
		// config de compilacao	
		// senha de criptografia xserial
		if(substr($arg, 0, 7)=='ignore='){
			$tmp = trim(substr($arg, 7));
			if($tmp!='')$IGNORES[]=$tmp;
			continue;
		}
		if($arg=='ignore' || $arg=='-i'){
			$tmp = (isset($argv[$n+1]) ? $argv[$n+1] : '');
			if($tmp!='')$IGNORES[]=$tmp;
			continue;
		}

		// diretorio de sondagem
		if(is_dir($arg)){ $DIRS[$C++] = $arg; continue; }
		if(is_file($arg) || is_link($arg)){
			fatal($arg."nao e' um diretorio");
		}

		// argumento desconhecido
		fatal("O argumento '".$arg."' nao foi reconhecido como diretorio, arquivo ou instrucao de compilacao");
	}
	
	if(count($DIRS)<2){
		fatal("O comparador requer pelo menos dois diretorios para comparar");
	}
	
	echo "* Opcoes:","\n";
	if(count($IGNORES)){
	foreach($IGNORES as $ig){
	echo " - Ignorar: ",$ig,"\n";
	}
	}

	echo "> Diretorios:","\n";
	foreach($DIRS as $dir){
	echo " => ",$dir,"\n";
	}

	echo "\n";



	// carregar arquivos dentro dos diretorios
	echo "* Carregando arquivos","\n";
	$errors = array();
	foreach($DIRS as $did=>$dir) {
		$dlen = strlen($dir);
		echo " > Carregando arquivos do diretorio '".$dir."'\n";
		
		// procurar todos os arquivos
		$list = find($dir);
		
		// juntar
		foreach($list as $file=>$size){
			if(is_dir($file)) continue;
			// obter sufixo de arquivo
			$sfile = substr($file, $dlen);
			
			if(isset($FILES[$sfile])){
				// colisao!
				$errors[] = "Colisao:\n\t".$FILES[$sfile][2]."\n\t".$file."\n\t\tprojetos:\n\t\t\t".$DIRS[$FILES[$sfile][1]]."\n\t\t\t".$dir."\n";
			}else{
				// arquivo normal
				$FILES[$sfile] = array(0=>$size, 1=>$did, 2=>$file);
			}
		}
	}
	if(count($errors)){
		echo "\n";
		echo ">> COLISOES ENCONTRADAS:","\n";
		foreach($errors as $err){
			echo " ",$err,"\n";
		}
		exit(500);
	}
	echo "\n";
	exit(0);



?>
